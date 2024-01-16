import 'package:equatable/equatable.dart';

class ParkingState extends Equatable {
  const ParkingState();

  @override
  List<Object> get props => [];
}

class SlotInitial extends ParkingState {}

class SlotLoading extends ParkingState {}

class SlotReleased extends ParkingState {}

class SlotAllocated extends ParkingState {
  const SlotAllocated(this.slot);
  @override
  final String slot;

  @override
  List<Object> get props => [slot];
}

class SlotError extends ParkingState {
  const SlotError(this.error);
  final String error;

  @override
  List<Object> get props => [error];
}
