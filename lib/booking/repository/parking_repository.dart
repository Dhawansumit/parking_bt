

import 'package:parking_bt/booking/domain/vehicle.dart';
import 'package:parking_bt/booking/service/parking_service.dart';

class ParkingRepository {

  ParkingRepository({required this.parkingService});
  final ParkingService parkingService;

  Future<String> getSlot(Vehicle vehicle) async {
    return parkingService.getSlot(vehicle);
  }

  releaseSlot({required String slot}) {
    return parkingService.releaseSlot(slot);
  }
}