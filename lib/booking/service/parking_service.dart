import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:parking_bt/booking/domain/vehicle.dart';


class ParkingService {
  ParkingService(this.functions);
  final dio = Dio();
  final FirebaseFunctions functions;

  Future<String> getSlot(Vehicle vehicle) async {
    try {
      final result;
      if (kIsWeb) {
        result = await dio.post(
          'https://us-central1-parking-bt.cloudfunctions.net/getSlot',
          options: Options(
            contentType: Headers.jsonContentType,
          ),
          data: {
            'data': {
              'parkingLotId': vehicle.parkingLotID,
              'carSize': vehicle.size,
              'carNumber': vehicle.vehicleNumber,
            },
          },
        );
        if (result.data != null) {
          return result.data['data']['slotNumber'].toString();
        } else {
          throw Exception('Unexpected response from server');
        }
      } else {
        final callable = functions.httpsCallable('getSlot');
        result = await callable.call({
          'parkingLotId': vehicle.parkingLotID,
          'carSize': vehicle.size,
          'carNumber': vehicle.vehicleNumber,
        });


      if (result.data != null) {
        return result.data['slotNumber'].toString();
      } else {
        throw Exception('Unexpected response from server');
      }
      }
    } catch (e) {
      throw Exception('Failed to get slot: $e');
    }
  }

  Future<void> releaseSlot(String slot) async {
    try {
      final result;
      if (kIsWeb) {
        result = await dio.post(
          'https://us-central1-parking-bt.cloudfunctions.net/freeSlot',
          options: Options(
            contentType: Headers.jsonContentType,
          ),
          data: {
            'data': {
              'parkingLotId': 'parking_lot_1',
              'slotId': slot,
              'carNumber': '',
            },
          },
        );
        if (result.data != null) {
        } else {
          throw Exception('Unexpected response from server');
        }
      } else {
        final callable = functions.httpsCallable('freeSlot');
        result = await callable.call({
          'parkingLotId': 'parking_lot_1',
          'slotId': slot,
          'carNumber': '',
        });
        if (result.data != null) {
        } else {
          throw Exception("Unexpected response from server");
        }
      }

    } catch (e) {
      throw Exception('Failed to release slot');
    }
  }
}
