import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parking_bt/booking/cubit/parking_cubit.dart';
import 'package:parking_bt/booking/state/parking_page_states.dart';
import 'package:parking_bt/booking/view/parking_page.dart';

class MockParkingCubit extends MockCubit<ParkingState>
    implements ParkingCubit {}

void main() {


  group('ParkingView', () {
    late ParkingCubit parkingCubit;

    setUp(() {
      parkingCubit = MockParkingCubit();
    });

    testWidgets('renders initial UI', (tester) async {
      when(() => parkingCubit.state).thenReturn(SlotInitial());
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: parkingCubit,
            child: ParkingView(),
          ),
        ),
      );

      expect(find.text('Parking Slot'), findsOneWidget);
      expect(find.text('Medium Car (Mini SUV)'), findsOneWidget);
      expect(find.text('Car Number (Optional)'), findsOneWidget);
      expect(find.text('Get Slot'), findsOneWidget);
    });

    testWidgets('calls getSlot when Get Slot button is tapped', (tester) async {
      when(() => parkingCubit.state).thenReturn(SlotInitial());
      when(() => parkingCubit.getSlot()).thenAnswer((_) async {});

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: parkingCubit,
            child: ParkingView(),
          ),
        ),
      );

      await tester.tap(find.text('Get Slot'));
      verify(() => parkingCubit.getSlot()).called(1);
      await tester.pump();
    });

    testWidgets('updates carNumber when TextField is changed', (tester) async {
      when(() => parkingCubit.state).thenReturn(SlotInitial());
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: parkingCubit,
            child: ParkingView(),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'ABC123');
      verify(() => parkingCubit.carNumberChanged('ABC123')).called(1);
    });

    testWidgets('opens release slot dialog when FloatingActionButton is tapped',
        (tester) async {
      when(() => parkingCubit.state).thenReturn(SlotInitial());
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: parkingCubit,
            child: ParkingView(),
          ),
        ),
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle(); // Wait for the dialog to appear

      expect(find.text('Release Slot Manually'), findsOneWidget);
    });
  });
}
