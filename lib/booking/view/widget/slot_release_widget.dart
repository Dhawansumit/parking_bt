import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:parking_bt/booking/cubit/parking_cubit.dart';
import 'package:parking_bt/booking/state/parking_page_states.dart';

class SlotReleaseUI extends StatelessWidget {
  SlotReleaseUI(this.slot, {super.key});

  String slot;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          elevation: 5, // Adjust the elevation for a shadow effect
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            width: 300, // Adjust the width as needed
            child: Column(
              children: [
                const Text(
                  'Parking Ticket',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                Text(
                  slot,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                const Text(
                  'Vehicle: ABC 123',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
                const Text(
                  'Issued on: 2024-01-16',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  r'Amount: $25.00',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Due by: 2024-01-31',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        BlocBuilder<ParkingCubit, ParkingState>(
          builder: (context, state) {
            return ElevatedButton(
              onPressed: () => context.read<ParkingCubit>().releaseSlot(slot),
              child: const Text('Release Slot'),
            );
          },
        ),
      ],
    );
  }
}
