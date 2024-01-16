import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:parking_bt/booking/cubit/parking_cubit.dart';
import 'package:parking_bt/booking/repository/parking_repository.dart';
import 'package:parking_bt/booking/service/parking_service.dart';
import 'package:parking_bt/booking/state/parking_page_states.dart';
import 'package:parking_bt/booking/view/widget/slot_release_widget.dart';
import 'package:parking_bt/l10n/l10n.dart';

class ParkingScreen extends StatelessWidget {
  const ParkingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ParkingCubit(
        parkingRepository: ParkingRepository(
          parkingService: ParkingService(FirebaseFunctions.instance),
        ),
      ),
      child: ParkingView(),
    );
  }
}

class ParkingView extends StatelessWidget {
  ParkingView({super.key});
  final TextEditingController _slotIdController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: const Text('Parking Slot')),
      body: Center(
        child: SizedBox(
          width: 400,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                    value: 'm', // Default value
                    items: const [
                      DropdownMenuItem(
                        value: 's',
                        child: Text('Small Car (HatchBack)'),
                      ),
                      DropdownMenuItem(
                        value: 'm',
                        child: Text('Medium Car (Mini SUV)'),
                      ),
                      DropdownMenuItem(
                        value: 'l',
                        child: Text('Large Car (Sedan)'),
                      ),
                      DropdownMenuItem(value: 'xl', child: Text('XLarge (SUV)')),
                    ],
                    onChanged: (carSize) {
                      print(carSize);
                      context.read<ParkingCubit>().carSizeChanged(carSize!);
                    }),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Car Number (Optional)',
                    hintText: 'Enter your car number (Optional)',
                  ),
                  onChanged: (carNumber) =>
                      context.read<ParkingCubit>().carNumberChanged(carNumber),
                ),
                const SizedBox(height: 16),
                BlocBuilder<ParkingCubit, ParkingState>(
                  builder: (context, state) {
                    return ElevatedButton(
                      onPressed: () => context.read<ParkingCubit>().getSlot(),
                      child: const Text('Get Slot'),
                    );
                  },
                ),
                SizedBox(height: 16),
                BlocBuilder<ParkingCubit, ParkingState>(
                  builder: (context, state) {
                    return _buildParkingInfo(state);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        _showReleaseSlotDialog(context);
      },
      child: Icon(Icons.add), // Change the icon as needed
    );
  }

  void _showReleaseSlotDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Release Slot Manually'),
          content: TextField(
            controller: _slotIdController,
            decoration: const InputDecoration(hintText: 'Enter slot ID'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                ctx.read<ParkingCubit>().releaseSlot(_slotIdController.text);
                _slotIdController.clear();
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Release'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildParkingInfo(ParkingState state) {
    if (state is SlotLoading) {
      return const CircularProgressIndicator(); // Show loading indicator
    } else if (state is SlotAllocated) {
      return SlotReleaseUI(state.slot);
    } else if (state is SlotError) {
      Fluttertoast.showToast(
        msg: state.error,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return Container();
    } else if (state is SlotReleased) {
      Fluttertoast.showToast(
        msg: 'Slot freed successfully',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16,
      );
      return Container();
    } else {
      return Container(); // Default or initial state
    }
  }
}
