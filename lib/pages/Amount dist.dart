import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:t_matatu/models/trantypes.dart';

import '../controllers/TypesController.dart';
import '../controllers/header.dart';
import '../controllers/vehicles/vehicles.dart';
import '../models/Transaction.dart' as tmatatu;
import '../models/vehicles/vehicle.dart';

class Distribute extends StatelessWidget {
  Distribute({super.key});

  final TextEditingController recamount = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final vehicleController = Get.find<VehiclesController>();
          final currentVehicle = vehicleController.Currentvehicle.value;
          return currentVehicle != null
              ? Text('${currentVehicle.Vehicle_Number} - ${currentVehicle.Fleet_No}')
              : const CircularProgressIndicator();
        }),
        titleTextStyle: const TextStyle(fontSize: 20, color: Colors.white),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          _buildAmountReceivedRow(), // Fixed at the top
          const SizedBox(height: 20), // Space between elements
          Expanded( // Make the transaction list take available space
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildTransactionList(context), // Only this part is scrollable
              ),
            ),
          ),
          const SizedBox(height: 20), // Space before footer
          _buildFooterRow(), // Fixed at the bottom
        ],
      ),
      resizeToAvoidBottomInset: true, // Allow resizing when the keyboard appears
    );
  }

  Widget _buildAmountReceivedRow() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Spacer(),
            SizedBox(
              width: 200,
              child: TextFormField(
                keyboardType: TextInputType.number,
                controller: recamount,
                decoration: const InputDecoration(
                  labelText: "Amount Received",
                  border: OutlineInputBorder(), // Add border to the text field
                ),
                onChanged: (value) {
                  // Handle input change if necessary
                },
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () {
                Get.find<TransTypeController>().distribute(double.tryParse(recamount.text) ?? 0);
              },
              icon: const Icon(Icons.post_add_sharp),
              iconSize: 50,
              color: Colors.blueAccent, // Change icon color
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(BuildContext context) {
    return Obx(() {
      final controller = Get.find<TransTypeController>();
      if (controller.loading.value) {
        return const CircularProgressIndicator();
      }

      return SizedBox(
        height: 500, // Adjust as necessary
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: controller.vehicleTrantypes.where((p0) => p0.Name != null).length,
          itemBuilder: (context, index) {
            return _buildTransactionCard(context, controller, index);
          },
        ),
      );
    });
  }

  Widget _buildTransactionCard(BuildContext context, TransTypeController controller, int index) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 8), // Add margin between cards
      child: GetBuilder<TransTypeController>(
        builder: (controller) {
          final transactionType = controller.vehicleTrantypes[index];
          return CheckboxListTile(
            dense: true,
            contentPadding: const EdgeInsets.only(left: 16, right: 16),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${transactionType.Name} (${NumberFormat("#,##0.00", "en_US").format(transactionType.Amounttoday ?? 0)}/${NumberFormat("#,##0.00", "en_US").format(transactionType.VehicleAmount ?? 0)})',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), // Improved font style
                ),
                Text(
                  NumberFormat("#,##0.00", "en_US").format(transactionType.Amountedited ?? 0),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent), // Highlighted amount
                ),
              ],
            ),
            subtitle: _buildTransactionAmountField(controller, index),
            tristate: true,
            checkColor: Colors.white,
            activeColor: Colors.blueAccent,
            value: transactionType.Checked,
            onChanged: (bool? value) => _onTransactionCheckboxChanged(context, controller, index, value),
          );
        },
      ),
    );
  }

  Widget _buildTransactionAmountField(TransTypeController controller, int index) {
    final transactionType = controller.vehicleTrantypes[index];
    return Visibility(
      visible: (transactionType.VehicleAmount! == 0 ||
          transactionType.Code == "SAVINGS" ||
          transactionType.Code == "SAVINGSCREW"),
      child: TextFormField(
        focusNode: transactionType.FocusNodes,
        keyboardType: TextInputType.number,
        controller: transactionType.eAmount,
        decoration: const InputDecoration(
          border: OutlineInputBorder(), // Add border to the text field
        ),
        onChanged: (value) {
          try {
            transactionType.Amountedited = double.parse(transactionType.eAmount.text);
          } catch (e) {
            print("Error: $e");
          }
        },
      ),
    );
  }

  Widget _buildFooterRow() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Use spaceBetween to distribute space evenly
        children: [
          const Spacer(),
          Expanded( // Use Expanded to allow the text to take available space
            child: Text(
              NumberFormat("#,##0.00", "en_US").format(Get.find<TransTypeController>().get_selected()),
              textAlign: TextAlign.center, // Center the text
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold), // Bold footer text
            ),
          ),
          const SizedBox(width: 16), // Add space between text and button
          GestureDetector(
            onTap: () {
              HeaderController().createlines();
              Get.find<HeaderController>().curTran = tmatatu.Trans().obs;
              Get.find<VehiclesController>().Currentvehicle = Vehicles().obs;
              Get.back();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.check, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Confirm',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onTransactionCheckboxChanged(BuildContext context, TransTypeController controller, int index, bool? value) {
    controller.toggle(index);
    if (value == true) {
      final transactionType = controller.vehicleTrantypes[index];
      if (transactionType.Amounttoday == transactionType.VehicleAmount && transactionType.VehicleAmount! > 0) {
        _showConfirmationDialog(context, transactionType, index);
      } else {
        double? vehicleAmount = transactionType.VehicleAmount;
        double? balance = vehicleAmount! > 0 ? vehicleAmount - transactionType.Amounttoday! : 0;
        balance = balance < 0 ? 0 : balance;
        transactionType.eAmount.text = '$balance';
        transactionType.Amountedited = balance;
      }
    } else {
      controller.vehicleTrantypes[index].eAmount.text = '0.0';
      controller.vehicleTrantypes[index].Amountedited = 0.0;
    }
    FocusScope.of(context).requestFocus(controller.vehicleTrantypes[index].FocusNodes);
    controller.vehicleTrantypes[index].eAmount.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.vehicleTrantypes[index].eAmount.text.length,
    );
  }

  void _showConfirmationDialog(BuildContext context, TranTypes types, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${types.Name} '),
          content: Text('${types.Name} is paid in full today. Add?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Add'),
            ),
          ],
        );
      },
    ).then((value) {
      if (value != null && value) {
        double? vehicleAmount = Get.find<TransTypeController>().vehicleTrantypes[index].VehicleAmount;
        double? balance = vehicleAmount! > 0 ? vehicleAmount - Get.find<TransTypeController>().vehicleTrantypes[index].Amounttoday! : 0;
        balance = balance < 0 ? 0 : balance;
        Get.find<TransTypeController>().vehicleTrantypes[index].eAmount.text = '${Get.find<TransTypeController>().vehicleTrantypes[index].VehicleAmount}';
        Get.find<TransTypeController>().vehicleTrantypes[index].Amountedited = Get.find<TransTypeController>().vehicleTrantypes[index].VehicleAmount;
      } else {
        Get.find<TransTypeController>().vehicleTrantypes[index].Checked = false;
      }
    });
  }
}
