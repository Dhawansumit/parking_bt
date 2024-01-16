#!/bin/bash

for ((i=1; i<=10; i++))
do
  # Replace the URL with your actual endpoint
  curl -X POST -H "Content-Type: application/json" -d '{"data":{"parkingLotId": "parking_lot_2", "carSize": "s", "carNumber": "ABC123"}}' https://us-central1-parking-bt.cloudfunctions.net/getSlot
done

# Wait for all background processes to finish
wait