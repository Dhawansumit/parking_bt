const functions = require("firebase-functions");
const admin = require("firebase-admin");
const cors = require("cors")({origin: true});

admin.initializeApp();

exports.getSlot = functions.https.onRequest(async (req, res) => {
  cors(req, res, async () => {
    if (req.method === "OPTIONS") {
      res.set("Access-Control-Allow-Methods", "POST");
      res.set("Access-Control-Allow-Headers", "Content-Type");
      res.status(204).send("");
      return;
    }
    // Handle the actual request
    if (req.method !== "POST") {
      res.status(400).send("Invalid request method");
      return;
    }
    const parkingLotId = req.body.data.parkingLotId;
    const carNumber = req.body.data.carNumber;
    const carSize = req.body.data.carSize;
    try {
      const parkingLotRef = admin
          .firestore()
          .collection("parking_lots")
          .doc(parkingLotId);
      let allocatedSlotNumber;
      const availableSlots = await findAvailableSlots(parkingLotRef, carSize);
      if (availableSlots.length > 0) {
        allocatedSlotNumber =
          await allocateSlot(admin.firestore(),
              parkingLotRef,
              availableSlots[0],
              carNumber,
          );
      }
      res.json({data: {slotNumber: allocatedSlotNumber || "NA"}});
    } catch (error) {
      console.error(error);
      res.status(500).json({error: "Failed to allocate slot"});
    }
  });
});

/**
 * Function to find available parking slots based on car size.
 * @param {Object} parkingLotRef - Reference to the parking lot in Firestore.
 * @param {string} carSize - Size of the car.
 * @return {Array} - Array of available parking slots.
 */
async function findAvailableSlots(parkingLotRef, carSize) {
  // Define the order of sizes to check based on the car size
  const sizeOrder = {
    "s": ["s", "m", "l", "xl"],
    "m": ["m", "l", "xl"],
    "l": ["l", "xl"],
    "xl": ["xl"],
  };

  const availableSlots = [];
  const levelSnapshot = parkingLotRef
      .collection("levels");
  for (const size of sizeOrder[carSize]) {
    for (const levelId of (await levelSnapshot.listDocuments() || {})) {
      const levelDoc = levelSnapshot.doc(levelId.id);
      const sizeQuerySnapshot = await levelDoc
          .collection("slots")
          .where("is_occupied", "==", false)
          .where("size", "==", size)
          .limit(1)
          .get();
      if (!sizeQuerySnapshot.empty) {
        const slotDoc = sizeQuerySnapshot.docs[0];
        availableSlots.push({levelId: levelId.id, bayId: slotDoc.id});
        break;
      }
      if (availableSlots.length > 0) {
        break;
      }
    }
    if (availableSlots.length > 0) {
      break;
    }
  }
  return availableSlots;
}


/**
 * Function to allocate a parking slot within a transaction.
 * @param {Object} firestore - Firestore instance.
 * @param {Object} parkingLotRef - Reference to the parking lot in Firestore.
 * @param {Object} allocatedSlot - Allocated slot information.
 * @param {string} carNumber - Car number.
 * @return {string} - Allocated slot number.
 */
async function allocateSlot(firestore,
    parkingLotRef,
    allocatedSlot,
    carNumber) {
  const {levelId, bayId, updateTime} = allocatedSlot;
  // Update database within transaction:
  await firestore.runTransaction(async (t) => {
    const levelRef = parkingLotRef
        .collection("levels")
        .doc(levelId);
    const slotRef = levelRef.collection("slots").doc(bayId);
    // Check optimistic locking
    const slotSnapshot = await t.get(slotRef);
    if (slotSnapshot.data().updateTime !== updateTime) {
      throw new Error("Data has changed, retrying...");
    }
    // Update slot and parkingLot
    t.update(slotRef, {is_occupied: true});
    t.update(slotRef, {carNumber: carNumber});
    t.update(slotRef, {updatedTime: new Date()});
    t.update(parkingLotRef, {
      updateTime: new Date(),
    });
  });
  return `${levelId}:${bayId}`;
}


exports.freeSlot = functions.https.onRequest(async (req, res) => {
  cors(req, res, async () => {
    if (req.method === "OPTIONS") {
      res.set("Access-Control-Allow-Methods", "POST");
      res.set("Access-Control-Allow-Headers", "Content-Type");
      res.status(204).send("");
      return;
    }
    // Handle the actual request
    if (req.method !== "POST") {
      res.status(400).send("Invalid request method");
      return;
    }
    try {
      const parkingLotId = req.body.data.parkingLotId;
      const slotId = req.body.data.slotId;
      const parts = slotId.split(":");
      const levelId = parts[0];
      const bayId = parts[1];
      const carNumber = req.body.data.carNumber;

      if (!parkingLotId || ((!levelId || !bayId) && !carNumber)) {
        return res.status(400)
            .json({error: "Please provide details to free the slot"});
      }

      const parkingLotRef = admin.firestore()
          .collection("parking_lots").doc(parkingLotId);

      // Free the slot based on either levelId and bayId or carNumber
      if (levelId && bayId) {
        await freeSlotBylevelAndBay(admin.firestore(),
            parkingLotRef, levelId, bayId);
      } else {
        await freeSlotByCarNumber(admin.firestore(), parkingLotRef, carNumber);
      }

      res.status(200).json({data: "Slot freed successfully"});
    } catch (error) {
      console.error(error);
      res.status(500).json({error: "Failed to free slot"});
    }
  });
});

/**
 * Function to free a parking slot based on level and bay.
 * @param {Object} firestore - Firestore instance.
 * @param {Object} parkingLotRef - Reference to the parking lot in Firestore.
 * @param {string} levelId - level ID.
 * @param {string} bayId - Bay ID.
 */
async function freeSlotBylevelAndBay(firestore, parkingLotRef, levelId, bayId) {
  // Update database within transaction to free the slot
  await firestore.runTransaction(async (t) => {
    const levelRef = parkingLotRef.collection("levels").doc(levelId);
    const slotRef = levelRef.collection("slots").doc(bayId);

    // Check optimistic locking or any other conditions if needed
    const slotSnapshot = await t.get(slotRef);
    if (slotSnapshot.data().is_occupied !== true) {
      throw new Error("Slot is not occupied, cannot free");
    }

    // Update slot and parkingLot to free the slot
    t.update(slotRef, {is_occupied: false});
    t.update(slotRef, {carNumber: null}); // Reset the car number if needed
    t.update(slotRef, {updatedTime: new Date()});
    t.update(parkingLotRef, {updateTime: new Date()});
  });
}

/**
 * Function to free a parking slot based on car number.
 * @param {Object} firestore - Firestore instance.
 * @param {Object} parkingLotRef - Reference to the parking lot in Firestore.
 * @param {string} carNumber - Car number.
 */
async function freeSlotByCarNumber(firestore, parkingLotRef, carNumber) {
  // Update database within transaction to free the slot
  await firestore.runTransaction(async (t) => {
    // Query for the slot based on carNumber
    const slotQuery = await firestore.collectionGroup("slots")
        .where("carNumber", "==", carNumber)
        .limit(1)
        .get();

    if (slotQuery.empty) {
      throw new Error(`No slot found with car number: ${carNumber}`);
    }

    const slotDoc = slotQuery.docs[0];
    const levelId = slotDoc.ref.parent.parent.id;
    const bayId = slotDoc.id;

    const levelRef = parkingLotRef.collection("levels").doc(levelId);
    const slotRef = levelRef.collection("slots").doc(bayId);

    // Check optimistic locking or any other conditions if needed
    const slotSnapshot = await t.get(slotRef);
    if (slotSnapshot.data().is_occupied !== true) {
      throw new Error("Slot is not occupied, cannot free");
    }

    // Update slot and parkingLot to free the slot
    t.update(slotRef, {is_occupied: false});
    t.update(slotRef, {carNumber: null}); // Reset the car number if needed
    t.update(slotRef, {updatedTime: new Date()});
    t.update(parkingLotRef, {updateTime: new Date()});
  });
}
