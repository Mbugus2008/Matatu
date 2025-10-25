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
  static const Color _primaryColor = Color(0xFF1565C0);
  static const Color _accentColor = Color(0xFF42A5F5);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Obx(() {
          final vehicleController = Get.find<VehiclesController>();
          final currentVehicle = vehicleController.Currentvehicle.value;
          return currentVehicle != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentVehicle.Vehicle_Number ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if ((currentVehicle.Fleet_No ?? '').isNotEmpty)
                      Text(
                        'Fleet ${currentVehicle.Fleet_No}',
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                )
              : const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2));
        }),
        titleTextStyle: const TextStyle(fontSize: 20, color: Colors.white),
        centerTitle: false,
        backgroundColor: _primaryColor,
        elevation: 4,
      ),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF5F6FA), Color(0xFFE3F2FD)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _buildAmountReceivedRow(),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _buildTransactionList(context),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: _buildFooterRow(),
              ),
            ],
          ),
        ),
      ),
      resizeToAvoidBottomInset: true,
    );
  }

  Widget _buildAmountReceivedRow() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                keyboardType: TextInputType.number,
                controller: recamount,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Enter amount',
                  prefixIcon: const Icon(Icons.payments_outlined, size: 20),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: _primaryColor, width: 1.3),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onChanged: (value) {},
              ),
            ),
            const SizedBox(width: 12),
            Tooltip(
              message: 'Distribute amount',
              child: SizedBox(
                height: 44,
                width: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: const CircleBorder(),
                    backgroundColor: _primaryColor,
                    elevation: 0,
                  ),
                  onPressed: () {
                    Get.find<TransTypeController>()
                        .distribute(double.tryParse(recamount.text) ?? 0);
                  },
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
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
        return const Center(child: CircularProgressIndicator());
      }

      final visibleCount =
          controller.vehicleTrantypes.where((p0) => p0.Name != null).length;
      if (visibleCount == 0) {
        return _buildEmptyState();
      }

      return ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 4),
        physics: const BouncingScrollPhysics(),
        itemCount: visibleCount,
        itemBuilder: (context, index) {
          return _buildTransactionCard(context, controller, index);
        },
        separatorBuilder: (_, __) => const SizedBox(height: 2),
      );
    });
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 0,
      color: Colors.white.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No distribution items found for this vehicle.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black54),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(
      BuildContext context, TransTypeController controller, int index) {
    return GetBuilder<TransTypeController>(
      builder: (controller) {
        final transactionType = controller.vehicleTrantypes[index];
        final currencyFormatter = NumberFormat('#,##0.00', 'en_US');
        final balance = (transactionType.VehicleAmount ?? 0) -
            (transactionType.Amounttoday ?? 0);
        final isNegative = balance < 0;
        final double vehicleAmount = transactionType.VehicleAmount ?? 0;
        final double amountToday = transactionType.Amounttoday ?? 0;
        const double amountPrecision = 0.01;
        final bool amountsMatch =
            (amountToday - vehicleAmount).abs() < amountPrecision &&
            vehicleAmount > 0;
        final bool hasAmountToday = amountToday > 0;

        Color amountTodayBackground;
        Color amountTodayIconColor;
        Color amountTodayTextColor;
        Color amountTodayBorderColor;

        if (!hasAmountToday) {
          amountTodayBackground = Colors.grey.shade200;
          amountTodayIconColor = Colors.grey.shade600;
          amountTodayTextColor = Colors.grey.shade800;
          amountTodayBorderColor = Colors.grey.shade300;
        } else if (amountsMatch) {
          amountTodayBackground = Colors.green.shade50;
          amountTodayIconColor = Colors.green.shade600;
          amountTodayTextColor = Colors.green.shade700;
          amountTodayBorderColor = Colors.green.shade200;
        } else {
          amountTodayBackground = Colors.orange.shade50;
          amountTodayIconColor = Colors.orange.shade600;
          amountTodayTextColor = Colors.orange.shade700;
          amountTodayBorderColor = Colors.orange.shade200;
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      transactionType.Name ?? 'Unnamed',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 2),
                  _buildAmountChip(
                    '',
                    currencyFormatter.format(vehicleAmount),
                    Icons.summarize_outlined,
                  ),
                  const SizedBox(width: 2),
                  _buildAmountChip(
                    '',
                    currencyFormatter.format(amountToday),
                    Icons.today_outlined,
                    backgroundColor: amountTodayBackground,
                    iconColor: amountTodayIconColor,
                    textColor: amountTodayTextColor,
                    borderColor: amountTodayBorderColor,
                  ),
                  const SizedBox(width: 2),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormatter.format(balance < 0 ? 0 : balance),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color:
                              isNegative ? Colors.redAccent : _primaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Icon(
                        isNegative
                            ? Icons.warning_amber_rounded
                            : Icons.payments_rounded,
                        color:
                            isNegative ? Colors.redAccent : _accentColor,
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
              CheckboxListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                value: transactionType.Checked ?? false,
                onChanged: (value) => _onTransactionCheckboxChanged(
                    context, controller, index, value),
                controlAffinity: ListTileControlAffinity.leading,
               
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: _buildAmountInput(controller, transactionType),
                ),
                
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAmountChip(
    String label,
    String value,
    IconData icon, {
    Color? backgroundColor,
    Color? iconColor,
    Color? textColor,
    Color? borderColor,
  }) {
    final displayText = label.isEmpty ? value : '$label: $value';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? Colors.black12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor ?? _accentColor),
          const SizedBox(width: 4),
          Text(
            displayText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  } 

  Widget _buildAmountInput(
      TransTypeController controller, TranTypes transactionType) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _accentColor.withOpacity(0.25)),
      ),
      child: TextFormField(
        focusNode: transactionType.FocusNodes,
        keyboardType: TextInputType.number,
        controller: transactionType.eAmount,
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          border: InputBorder.none,
        ),
        onChanged: (value) {
          final parsedValue = double.tryParse(value) ?? 0;
          transactionType.Amountedited = parsedValue;
          controller.update(['footer']);
        },
      ),
    );
  }

  Widget _buildFooterRow() {
    return GetBuilder<TransTypeController>(
      id: 'footer',
      builder: (controller) {
        final totalSelected = controller.get_selected() ?? 0;
        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Selected',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        NumberFormat('#,##0.00', 'en_US').format(totalSelected),
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    HeaderController().createlines();
                    Get.find<HeaderController>().curTran = tmatatu.Trans().obs;
                    Get.find<VehiclesController>().Currentvehicle.value =
                        Vehicles();
                    Get.back();
                  },
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_primaryColor, _accentColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withOpacity(0.25),
                          offset: const Offset(0, 4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.check_circle_outline,
                            color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Confirm',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onTransactionCheckboxChanged(BuildContext context,
      TransTypeController controller, int index, bool? value) {
    controller.toggle(index);
    if (value == true) {
      final transactionType = controller.vehicleTrantypes[index];
      if (transactionType.Amounttoday == transactionType.VehicleAmount &&
          transactionType.VehicleAmount! > 0) {
        _showConfirmationDialog(context, transactionType, index);
      } else {
        double? vehicleAmount = transactionType.VehicleAmount;
        double? balance = vehicleAmount! > 0
            ? vehicleAmount - transactionType.Amounttoday!
            : 0;
        balance = balance < 0 ? 0 : balance;
        transactionType.eAmount.text = '$balance';
        transactionType.Amountedited = balance;
      }
    } else {
      controller.vehicleTrantypes[index].eAmount.text = '0.0';
      controller.vehicleTrantypes[index].Amountedited = 0.0;
    }
    FocusScope.of(context)
        .requestFocus(controller.vehicleTrantypes[index].FocusNodes);
    controller.vehicleTrantypes[index].eAmount.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.vehicleTrantypes[index].eAmount.text.length,
    );
  }

  void _showConfirmationDialog(
      BuildContext context, TranTypes types, int index) {
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
        double? vehicleAmount = Get.find<TransTypeController>()
            .vehicleTrantypes[index]
            .VehicleAmount;
        double? balance = vehicleAmount! > 0
            ? vehicleAmount -
                Get.find<TransTypeController>()
                    .vehicleTrantypes[index]
                    .Amounttoday!
            : 0;
        balance = balance < 0 ? 0 : balance;
        Get.find<TransTypeController>().vehicleTrantypes[index].eAmount.text =
            '${Get.find<TransTypeController>().vehicleTrantypes[index].VehicleAmount}';
        Get.find<TransTypeController>().vehicleTrantypes[index].Amountedited =
            Get.find<TransTypeController>()
                .vehicleTrantypes[index]
                .VehicleAmount;
      } else {
        Get.find<TransTypeController>().vehicleTrantypes[index].Checked = false;
      }
    });
  }
}



