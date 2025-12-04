import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:t_matatu/models/vehicles/vehicle.dart';

import '../controllers/waybill_revenue_controller.dart';

class WaybillRevenuePage extends GetView<WaybillRevenueController> {
  WaybillRevenuePage({super.key});

  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Revenue & Waybill'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: controller.formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildVehicleSelector(),
                  const SizedBox(height: 16),
                  _buildDatePicker(context),
                  const SizedBox(height: 16),
                  _buildSummaryCard(context),
                  const SizedBox(height: 16),
                  _buildNumericField(
                    fieldController: controller.targetController,
                    label: 'Target Revenue',
                    validatorMessage: 'Enter target revenue',
                  ),
                  const SizedBox(height: 16),
                  _buildNumericField(
                    fieldController: controller.offloadController,
                    label: 'Offload Per Trip',
                    validatorMessage: 'Enter offload amount',
                  ),
                  const SizedBox(height: 16),
                  Obx(
                    () => SwitchListTile.adaptive(
                      value: controller.waybillEndorsed.value,
                      title: const Text('Waybill Endorsed'),
                      onChanged: (bool value) =>
                          controller.waybillEndorsed.value = value,
                    ),
                  ),
                  Obx(
                    () => SwitchListTile.adaptive(
                      value: controller.feesPaid.value,
                      title: const Text('Fees Paid'),
                      onChanged: (bool value) =>
                          controller.feesPaid.value = value,
                    ),
                  ),
                  TextFormField(
                    controller: controller.notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Obx(
                          () => ElevatedButton.icon(
                            onPressed: controller.isSaving.value
                                ? null
                                : controller.saveEntry,
                            icon: controller.isSaving.value
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.save_alt),
                            label: const Text('Save & Sync'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Obx(
                        () => OutlinedButton.icon(
                          onPressed: controller.isSyncing.value
                              ? null
                              : controller.syncPendingEntries,
                          icon: controller.isSyncing.value
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.sync),
                          label: const Text('Sync Pending'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Entries are saved locally first and will automatically sync once connectivity returns.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleSelector() {
    return Obx(
      () {
        final controller = Get.find<WaybillRevenueController>();
        final vehicles = controller.vehicles;
        final selected = controller.selectedVehicle.value;
        final String? currentValue = selected == null
            ? null
            : (selected.Code ?? selected.Vehicle_Number ?? selected.Fleet_No);
        return DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
          value: currentValue,
          items: vehicles
              .map(
                (vehicle) => DropdownMenuItem<String>(
                  value: vehicle.Code ??
                      vehicle.Vehicle_Number ??
                      vehicle.Fleet_No,
                  child:
                      Text(vehicle.Vehicle_Number ?? vehicle.Code ?? 'Vehicle'),
                ),
              )
              .toList(),
          onChanged: (String? value) {
            Vehicles? selectedVehicle;
            for (final Vehicles vehicle in vehicles) {
              final String identifier = vehicle.Code ??
                  vehicle.Vehicle_Number ??
                  vehicle.Fleet_No ??
                  '';
              if (identifier == value) {
                selectedVehicle = vehicle;
                break;
              }
            }
            controller.setVehicle(selectedVehicle);
          },
          decoration: const InputDecoration(
            labelText: 'Vehicle',
            border: OutlineInputBorder(),
          ),
          validator: (String? value) =>
              value == null || value.isEmpty ? 'Select a vehicle' : null,
        );
      },
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return Obx(
      () => InkWell(
        onTap: () => controller.pickDate(context),
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Date',
            border: OutlineInputBorder(),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(_dateFormat.format(controller.selectedDate.value)),
              const Icon(Icons.calendar_today, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Obx(
      () {
        final double target = controller.targetValue;
        final double actual = controller.actualRevenue.value;
        final double variance = controller.variance;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Daily Summary',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _summaryRow('Target', target.toStringAsFixed(2)),
                const SizedBox(height: 8),
                _summaryRow('Actual Collections', actual.toStringAsFixed(2)),
                const Divider(height: 24),
                _summaryRow(
                  'Variance',
                  variance.toStringAsFixed(2),
                  valueStyle: TextStyle(
                    color: variance >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _summaryRow(String label, String value, {TextStyle? valueStyle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(label),
        Text(value, style: valueStyle),
      ],
    );
  }

  Widget _buildNumericField({
    required TextEditingController fieldController,
    required String label,
    required String validatorMessage,
  }) {
    return TextFormField(
      controller: fieldController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (String? value) {
        if (value == null || value.trim().isEmpty) {
          return validatorMessage;
        }
        if (double.tryParse(value.trim()) == null) {
          return 'Enter a valid number';
        }
        return null;
      },
    );
  }
}
