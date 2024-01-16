import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parking_bt/booking/cubit/parking_cubit.dart';
import 'package:parking_bt/booking/domain/vehicle.dart';
import 'package:parking_bt/booking/repository/parking_repository.dart';
import 'package:parking_bt/booking/state/parking_page_states.dart';

class MockParkingRepository extends Mock implements ParkingRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      Vehicle(
        size: 'fakeSize',
        vehicleNumber: 'fakeNumber',
        parkingLotID: 'fakeParkingLotID',
      ),
    );
  });

  late ParkingCubit parkingCubit;
  late MockParkingRepository mockParkingRepository;

  setUp(() {
    mockParkingRepository = MockParkingRepository();
    parkingCubit = ParkingCubit(parkingRepository: mockParkingRepository);
  });

  test('emits initial state', () {
    final parkingCubit =
        ParkingCubit(parkingRepository: MockParkingRepository());
    expect(parkingCubit.state, const ParkingState());
  });

  test('emits SlotInitial when car size is changed', () {
    final parkingCubit =
        ParkingCubit(parkingRepository: MockParkingRepository());
    parkingCubit.carSizeChanged('l');
    expect(parkingCubit.state, SlotInitial());
  });

  test('emits SlotInitial when car number is changed', () {
    final parkingCubit =
        ParkingCubit(parkingRepository: MockParkingRepository());
    parkingCubit.carNumberChanged('ABC123');
    expect(parkingCubit.state, SlotInitial());
  });

  blocTest<ParkingCubit, ParkingState>(
    'emits SlotLoading and SlotAllocated states when getSlot is successful',
    build: () {
      when(() => mockParkingRepository.getSlot(any()))
          .thenAnswer((_) async => 'A1:1');
      return ParkingCubit(parkingRepository: mockParkingRepository);
    },
    act: (cubit) => cubit.getSlot(),
    expect: () => <ParkingState>[
      SlotLoading(),
      const SlotAllocated('A1:1'),
    ],
  );

  blocTest<ParkingCubit, ParkingState>(
    'emits SlotLoading and SlotError states when getSlot encounters an error',
    build: () {
      when(() => mockParkingRepository.getSlot(any())).thenThrow('Error');
      return ParkingCubit(parkingRepository: mockParkingRepository);
    },
    act: (cubit) => cubit.getSlot(),
    expect: () => <ParkingState>[
      SlotLoading(),
      const SlotError('Error'),
    ],
  );

  blocTest<ParkingCubit, ParkingState>(
    'emits SlotLoading and SlotReleased states when releaseSlot is successful',
    build: () {
      when(() => mockParkingRepository.releaseSlot(slot: any(named: 'slot')))
          .thenAnswer((_) async => null);
      return ParkingCubit(parkingRepository: mockParkingRepository);
    },
    act: (cubit) => cubit.releaseSlot('A1:1'),
    expect: () => <ParkingState>[
      SlotLoading(),
      SlotReleased(),
    ],
  );

  blocTest<ParkingCubit, ParkingState>(
    'emits SlotError for invalid slot format',
    build: () {
      return ParkingCubit(parkingRepository: MockParkingRepository());
    },
    act: (cubit) => cubit.releaseSlot('invalid'),
    expect: () => <ParkingState>[
      SlotLoading(),
      const SlotError('Invalid slot format. Correct format<floor>:<bay>'),
    ],
  );

  blocTest<ParkingCubit, ParkingState>(
    'emits SlotLoading and SlotError states when releaseSlot encounters an error',
    build: () {
      when(() => mockParkingRepository.releaseSlot(slot: any(named: 'slot')))
          .thenThrow('Error');
      return ParkingCubit(parkingRepository: mockParkingRepository);
    },
    act: (cubit) => cubit.releaseSlot('A1:1'),
    expect: () => <ParkingState>[
      SlotLoading(),
      const SlotError('Error'),
    ],
  );

}
