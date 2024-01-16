import 'package:bloc/bloc.dart';
import 'package:parking_bt/booking/domain/vehicle.dart';
import 'package:parking_bt/booking/repository/parking_repository.dart';
import 'package:parking_bt/booking/state/parking_page_states.dart';

class ParkingCubit extends Cubit<ParkingState> {
  ParkingCubit({required this.parkingRepository}) : super(const ParkingState());
  final ParkingRepository parkingRepository;

  String _carSize = 'm'; // Default car size
  String _carNumber = '';

  void carSizeChanged(String carSize) {
    _carSize = carSize;
    emit(SlotInitial());
  }

  void carNumberChanged(String carNumber) {
    _carNumber = carNumber;
    emit(SlotInitial());
  }

  Future<void> getSlot() async {
    if (_carSize.isEmpty && _carNumber.isEmpty) {
      // Handle missing input (e.g., display an error message)
      return;
    }
    emit(SlotLoading());

    try {
      final slot = await parkingRepository.getSlot(
        Vehicle(
          size: _carSize,
          vehicleNumber: _carNumber,
          parkingLotID: 'parking_lot_1',
        ),
      );
      if (slot == 'NA') {
        emit(const SlotError('Parking Full, Please try after some time'));
        return;
      }
      emit(SlotAllocated(slot));
    } catch (error) {
      emit(SlotError(error.toString()));
    }
  }

  Future<void> releaseSlot(String slot) async {
    emit(SlotLoading());

    try {
      final slotPattern = RegExp(r'^.+:.+$');
      if (!slotPattern.hasMatch(slot)) {
        emit(
          const SlotError('Invalid slot format. Correct format<floor>:<bay>'),
        );
        return;
      }
      await parkingRepository.releaseSlot(
        slot: slot.toUpperCase(),
      );
      emit(SlotReleased());
    } catch (error) {
      emit(SlotError(error.toString()));
    }
  }
}
