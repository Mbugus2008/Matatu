// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:t_matatu/controllers/main.dart';
import 'package:t_matatu/models/enums.dart';
import 'package:t_matatu/models/vehicles/vehicle.dart';
import 'package:t_matatu/reports/controller.dart';

import '../models/vehicles/DeportandFuel.dart';

class Fuel extends StatefulWidget {
  const Fuel({Key? key}) : super(key: key);

  @override
  State<Fuel> createState() => _FuelState();
}

/// Wrapper with own AppBar for standalone use (not via PageLoader)
class FuelScreen extends StatefulWidget {
  const FuelScreen({Key? key}) : super(key: key);

  @override
  State<FuelScreen> createState() => _FuelScreenState();
}

class _FuelScreenState extends State<FuelScreen> {
  DateTime? _selectedDate;
  bool _dateIsPreset = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = Get.find<ReportController>().selectedDate?.value;
    _dateIsPreset = _selectedDate != null;
  }

  Color _primaryColor() {
    final hex = Get.find<MainController>().config?.value.theme?.primaryColor;
    if (hex == null) return Colors.blue;
    final clean = hex.replaceFirst('#', '');
    final full = clean.length == 6 ? 'FF$clean' : clean;
    return Color(int.parse(full, radix: 16));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      Get.find<ReportController>().selectedDate?.value = picked;
      DepotFuel().getdata(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fuel', style: TextStyle(fontSize: 16)),
        centerTitle: true,
        toolbarHeight: 44,
        backgroundColor: _primaryColor(),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _dateIsPreset ? null : _pickDate,
              icon: Icon(
                _dateIsPreset ? Icons.lock : Icons.calendar_today,
                size: 16,
                color: Colors.white,
              ),
              label: Text(
                _selectedDate != null
                    ? DateFormat('dd-MMM-yyyy').format(_selectedDate!)
                    : 'Select Date',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: const Fuel(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (Get.find<ReportController>().selectedDate?.value != null) {
            Get.find<FuelController>().updateDepot();
          } else {
            Get.snackbar('No Date', 'Please select a date first');
          }
        },
        icon: const Icon(Icons.cloud_upload, color: Colors.white),
        label: const Text('Update',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: _primaryColor(),
      ),
    );
  }
}

class _FuelState extends State<Fuel> {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<FuelController>(
      init: FuelController(),
      builder: (fuelController) {
        return GetBuilder<DepotController>(
          init: DepotController(),
          builder: (depotController) {
            return Column(
              children: [
                _buildSummaryCard(),
                _buildSearchField(),
                Expanded(child: _buildVehicleList()),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryCard() {
    return Obx(() {
      final depot = Get.find<DepotController>().depottrans;
      final hasDate = Get.find<ReportController>().selectedDate?.value != null;
      final totalVehicles = depot.length;
      final totalCollection =
          depot.fold<double>(0, (sum, d) => sum + (d.Total_Collection ?? 0));
      final totalFuelLtrs =
          depot.fold<double>(0, (sum, d) => sum + (d.Total_litres ?? 0));
      final totalFuelAmt =
          depot.fold<double>(0, (sum, d) => sum + (d.Fuel ?? 0));
      final totalPaid =
          depot.fold<double>(0, (sum, d) => sum + (d.Amount_Paid ?? 0));

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: Colors.green.shade50,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(hasDate ? 'Fuel Summary' : 'No date selected',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('$totalVehicles vehicles',
                      style: const TextStyle(fontSize: 11)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _summaryTile('Collection',
                      NumberFormat('#,##0').format(totalCollection)),
                  const SizedBox(width: 4),
                  _summaryTile(
                      'Fuel (L)', NumberFormat('#,##0').format(totalFuelLtrs)),
                  const SizedBox(width: 4),
                  _summaryTile(
                      'Fuel Amt', NumberFormat('#,##0').format(totalFuelAmt)),
                  const SizedBox(width: 4),
                  _summaryTile('Paid', NumberFormat('#,##0').format(totalPaid)),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _summaryTile(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.green)),
          Text(label,
              style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextFormField(
      onChanged: (value) {
        value = value.toUpperCase();
        Get.find<DepotController>().filterDepotTrans(value);
      },
      textAlign: TextAlign.center,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search, color: Colors.blue),
        floatingLabelAlignment: FloatingLabelAlignment.center,
        labelText: 'Find Vehicle',
        labelStyle: TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _buildVehicleList() {
    return Obx(() {
      var controller = Get.find<DepotController>();
      if (controller.depottrans.isEmpty) {
        return Center(child: Text('No vehicles available'));
      }
      return ListView.builder(
        itemCount: controller.depottrans.length,
        itemBuilder: (BuildContext context, int index) {
          return _buildVehicleCard(index);
        },
      );
    });
  }

  Widget _buildVehicleCard(int index) {
    final vehiclesController = Get.find<DepotController>();
    final vehicle = vehiclesController.depottrans[index];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Card(
        elevation: 8, // Increased elevation for more pronounced shadow
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        shadowColor: Colors.grey.withOpacity(0.5), // Softer shadow color
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey.shade100],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.max,
              children: [
                _buildVehicleHeader(vehicle),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(child: _buildFuelInputs(vehicle)),
                    _buildFinancialInfo(vehicle),
                  ],
                ),
                const Divider(height: 12),
                _buildCardSummary(vehicle),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardSummary(DepotFuel vehicle) {
    final subNet =
        (vehicle.Total_Collection ?? 0) - (vehicle.Management_Target ?? 0);
    return Row(
      children: [
        _miniTile('Collection',
            NumberFormat('#,##0').format(vehicle.Total_Collection ?? 0)),
        Container(width: 1, height: 20, color: Colors.grey.shade300),
        _miniTile('Fuel', NumberFormat('#,##0').format(vehicle.Fuel ?? 0)),
        Container(width: 1, height: 20, color: Colors.grey.shade300),
        _miniTile(
            'Paid', NumberFormat('#,##0').format(vehicle.Amount_Paid ?? 0)),
        Container(width: 1, height: 20, color: Colors.grey.shade300),
        _miniTile('Sub Net', NumberFormat('#,##0').format(subNet)),
      ],
    );
  }

  Widget _miniTile(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          Text(label,
              style: TextStyle(fontSize: 8, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildVehicleHeader(DepotFuel vehicle) {
    print('Driver Name: ${vehicle.Driver_Name}');
    print('Conductor Name: ${vehicle.Conductor_Name}');
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 14, color: Colors.blue.shade900),
                    children: [
                      TextSpan(
                        text: '${vehicle.Fleet} ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: '| '),
                      TextSpan(
                        text: '${vehicle.Vehicle} ',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              if (vehicle.Driver_Name != null || vehicle.Driver != null)
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Drv: ',
                        style: TextStyle(fontWeight: FontWeight.normal),
                      ),
                      TextSpan(
                        text:
                            '${vehicle.Driver ?? ''}${vehicle.Driver != null && vehicle.Driver_Name != null ? ' | ' : ''}${vehicle.Driver_Name ?? ''}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                    style: TextStyle(fontSize: 10, color: Colors.blue.shade800),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              if (vehicle.Conductor_Name != null || vehicle.Conductor != null)
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Cndtr: ',
                        style: TextStyle(fontWeight: FontWeight.normal),
                      ),
                      TextSpan(
                        text:
                            '${vehicle.Conductor ?? ''}${vehicle.Conductor != null && vehicle.Conductor_Name != null ? ' | ' : ''}${vehicle.Conductor_Name ?? ''}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                    style: TextStyle(fontSize: 10, color: Colors.blue.shade800),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${vehicle_type_desc.desc[vehicle.Capacity]}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverInfo(DepotFuel vehicle) {
    return GestureDetector(
      onTap: () => _showDriverInfoPopup(Get.context!, vehicle),
      child: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: SizedBox(
          width: 60,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(vehicle.Driver ?? '',
                  style: const TextStyle(fontSize: 11),
                  overflow: TextOverflow.ellipsis),
              Text(vehicle.Driver_Name ?? '',
                  style: const TextStyle(fontSize: 9),
                  overflow: TextOverflow.ellipsis),
              Text(vehicle.Conductor ?? '',
                  style: const TextStyle(fontSize: 11),
                  overflow: TextOverflow.ellipsis),
              Text(vehicle.Conductor_Name ?? '',
                  style: const TextStyle(fontSize: 9),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  void _showDriverInfoPopup(BuildContext context, dynamic vehicle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Vehicle Details',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Fleet', vehicle.Fleet),
                _buildInfoRow('Vehicle', vehicle.Vehicle),
                _buildInfoRow(
                    'Capacity', vehicle_type_desc.desc[vehicle.Capacity]),
                Divider(height: 20, thickness: 1),
                _buildInfoRow('Driver', vehicle.Driver),
                _buildInfoRow('Driver Name', vehicle.Driver_Name),
                Divider(height: 20, thickness: 1),
                _buildInfoRow('Conductor', vehicle.Conductor),
                _buildInfoRow('Conductor Name', vehicle.Conductor_Name),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close', style: TextStyle(color: Colors.blue)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.grey[700]),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value ?? 'N/A',
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuelInputs(DepotFuel vehicle) {
    // Assumes vehicle.litres_focus_node, vehicle.fuel_focus_node,
    // vehicle.amount_paid_focus_node, vehicle.milleage_focus_node are defined and initialized in DepotFuel model
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTextField(
            vehicle.litres_editor,
            'Litres',
            (value) => vehicle.Total_litres = double.tryParse(value) ??
                0, // onChanged: updates model property
            vehicle.Total_litres == null || vehicle.Total_litres == 0
                ? ""
                : vehicle.Total_litres!.toStringAsFixed(2),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            focusNode:
                vehicle.litres_focus_node, // Pass the FocusNode from the model
            // onFocusLost: () { /* specific action for litres if needed, e.g. _updateBalance(vehicle); */ },
          ),
          SizedBox(height: 10),
          _buildTextField(
            vehicle.fuel_editor,
            'Fuel (Kshs)',
            (value) {
              // onChanged: ONLY updates model property
              vehicle.Fuel = double.tryParse(value) ?? 0;
            },
            vehicle.Fuel == null || vehicle.Fuel == 0
                ? ""
                : vehicle.Fuel!.toStringAsFixed(2),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            focusNode:
                vehicle.fuel_focus_node, // Pass the FocusNode from the model
            onFocusLost: () {
              // onFocusLost: triggers balance update
              print('Focus lost for Fuel (Kshs), updating balance.');
              _updateBalance(vehicle);
            },
          ),
          SizedBox(height: 10),
          _buildTextField(
            vehicle.amountpaid_editor,
            'Paid Amount (Kshs)',
            (value) {
              // onChanged: ONLY updates model property
              vehicle.Amount_Paid = double.tryParse(value) ?? 0;
            },
            vehicle.Amount_Paid == null || vehicle.Amount_Paid == 0
                ? ""
                : vehicle.Amount_Paid!.toStringAsFixed(2),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            focusNode: vehicle
                .amount_paid_focus_node, // Pass the FocusNode from the model
            onFocusLost: () {
              // onFocusLost: triggers balance update
              print('Focus lost for Paid Amount (Kshs), updating balance.');
              _updateBalance(vehicle);
            },
          ),
          SizedBox(height: 10),
          _buildTextField(
            vehicle.milleage_editor,
            'Odometer',
            (value) => vehicle.Odometer_Reading = double.tryParse(value) ?? 0,
            vehicle.Odometer_Reading?.toStringAsFixed(0) ?? "",
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    Function(String) onChanged,
    String initialValue, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    FocusNode? focusNode, // Added: for focus control
    VoidCallback? onFocusLost, // Added: callback for when focus is lost
  }) {
    IconData icon;
    switch (hint) {
      case 'Fuel(Kes)':
        icon = Icons.money_off_csred_rounded;
        break;
      case 'Amount Paid':
        icon = Icons.attach_money;
        break;
      case 'Millage':
      case 'Odometer':
        icon = Icons.speed;
        break;
      case 'Litres':
        icon = Icons.local_gas_station;
        break;
      default:
        icon = Icons.edit;
    }

    controller.text = initialValue;

    return Focus(
      focusNode: focusNode, // Use the passed focusNode for the Focus widget
      onFocusChange: (hasFocus) {
        if (!hasFocus && onFocusLost != null) {
          // print('Focus lost for $hint (via Focus widget)'); // Already printed in _buildFuelInputs specific callback
          onFocusLost();
        }
      },
      child: TextField(
        keyboardType: keyboardType ?? TextInputType.text,
        controller: controller,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 12),
          prefixIcon: Icon(icon, size: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        ),
        onTap: () {
          controller.selection = TextSelection(
            baseOffset: 0,
            extentOffset: controller.text.length,
          );
        },
        onEditingComplete: () {
          // Called when the user presses the 'done' button on the keyboard.
          // You might want to unfocus here: FocusScope.of(context).unfocus();
          // Or, if onFocusLost isn't triggering as expected with the keyboard 'done' action,
          // you could also call onFocusLost here if focusNode.hasFocus is false.
          print('onEditingComplete for $hint');
          if (focusNode != null && !focusNode.hasFocus && onFocusLost != null) {
            // This can be a fallback if onFocusChange isn't triggered by keyboard's done action
            // print('Triggering onFocusLost from onEditingComplete for $hint');
            // onFocusLost();
          }
        },
        onChanged: (value) {
          // print('TextField changed: $hint = $value'); // Debug print
          onChanged(
              value); // This now correctly calls the (value) => vehicle.Property = ... function
        },
        inputFormatters: inputFormatters,
      ), // Closes TextField
    ); // Closes Focus
  }

  Widget _buildFinancialInfo(DepotFuel vehicle) {
    print(
        'Building Financial Info for ${vehicle.Vehicle}, Fuel Balance: ${vehicle.Balance}');
    final subNet =
        (vehicle.Total_Collection ?? 0) - (vehicle.Management_Target ?? 0);
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: SizedBox(
        width: 160,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('Total Collection',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis),
            Text(NumberFormat('#,##0').format(vehicle.Total_Collection ?? 0),
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: (vehicle.Total_Collection ?? 0) >= 0
                        ? Colors.green
                        : Colors.red),
                overflow: TextOverflow.ellipsis),
            const Divider(height: 8, thickness: 1),
            const Text('Mngmt',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis),
            Text(NumberFormat('#,##0').format(vehicle.Management_Target ?? 0),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: (vehicle.Management_Target ?? 0) >= 0
                        ? Colors.green
                        : Colors.red),
                overflow: TextOverflow.ellipsis),
            const Divider(height: 8, thickness: 1),
            const Text('Sub Net',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis),
            Text(NumberFormat('#,##0').format(subNet),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: subNet >= 0 ? Colors.green : Colors.red),
                overflow: TextOverflow.ellipsis),
            const Divider(height: 8, thickness: 1),
            Row(
              children: [
                const Text('Unpaid',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const Spacer(),
                const Text('Bal',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            Row(
              children: [
                Text(
                    NumberFormat('#,##0').format(
                        ((vehicle.Fuel ?? 0) - (vehicle.Amount_Paid ?? 0))
                            .clamp(0.0, double.infinity)),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color:
                            ((vehicle.Fuel ?? 0) - (vehicle.Amount_Paid ?? 0)) >
                                    0
                                ? Colors.red
                                : Colors.green)),
                const Spacer(),
                Text(
                    NumberFormat('#,##0').format(((subNet -
                                ((vehicle.Fuel ?? 0) -
                                        (vehicle.Amount_Paid ?? 0))
                                    .clamp(0.0, double.infinity)) >
                            0)
                        ? 0
                        : subNet -
                            ((vehicle.Fuel ?? 0) - (vehicle.Amount_Paid ?? 0))
                                .clamp(0.0, double.infinity)),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: (subNet -
                                    ((vehicle.Fuel ?? 0) -
                                            (vehicle.Amount_Paid ?? 0))
                                        .clamp(0.0, double.infinity)) >
                                0
                            ? Colors.green
                            : Colors.red)),
              ],
            ),
            const Divider(height: 8, thickness: 1),
            const Text('Offload',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis),
            Text(
                NumberFormat('#,##0').format(subNet -
                    ((vehicle.Fuel ?? 0) - (vehicle.Amount_Paid ?? 0))
                        .clamp(0.0, subNet > 0 ? subNet : 0.0)),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green),
                overflow: TextOverflow.ellipsis),
            const Divider(height: 8, thickness: 1),
            const Text('Deficit Responsibility',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis),
            Container(
              width: 150,
              child: DropdownButtonFormField<Whos_to_blame>(
                value: vehicle.Whos_to_blame_for_Deficiet,
                selectedItemBuilder: (context) {
                  return Whos_to_blame.values.map((value) {
                    return Text(
                      Whos_to_blame_for_Deficiet_desc.desc[value] ?? 'Unknown',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade900,
                          fontWeight: FontWeight.bold),
                    );
                  }).toList();
                },
                items: Whos_to_blame.values.map((Whos_to_blame value) {
                  return DropdownMenuItem<Whos_to_blame>(
                    value: value,
                    child: Text(
                      Whos_to_blame_for_Deficiet_desc.desc[value] ?? 'Unknown',
                      style:
                          TextStyle(fontSize: 12, color: Colors.blue.shade800),
                    ),
                  );
                }).toList(),
                onChanged: (Whos_to_blame? value) {
                  vehicle.Whos_to_blame_for_Deficiet = value;
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.blue.shade500, width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.blue.shade400, width: 1.0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.blue.shade50,
                ),
                dropdownColor: Colors.blue.shade50,
                isExpanded: true,
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade900,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateBalance(DepotFuel vehicle) {
    var controller = Get.find<DepotController>();
    double totalCollection = vehicle.Total_Collection ?? 0;
    double mgmtTarget = vehicle.Management_Target ?? 0;
    double amountPaid = vehicle.Amount_Paid ?? 0;
    double fuelCost = vehicle.Fuel ?? 0;
    double subNet = totalCollection - mgmtTarget;
    double fuelBal = subNet + amountPaid - fuelCost;
    double newBalance = fuelBal > 0 ? subNet : fuelBal;

    print(
        'Updating Fuel Balance for ${vehicle.Vehicle}: SubNet=$subNet + Paid=$amountPaid - Fuel=$fuelCost = $fuelBal -> $newBalance');

    controller.depottrans
        .firstWhere((element) =>
            element.Vehicle == vehicle.Vehicle && element.Date == vehicle.Date)
        .Balance = newBalance;

    controller.update();
  }
}

class FuelController extends GetxController {
  bool isLoading = false;
  bool isUpdating = false;

  Future<void> updateDepot() async {
    isUpdating = true;
    update();
    try {
      await DepotFuel().updatedepot(Get.find<DepotController>().depottrans);
      Get.snackbar('Success', 'Depot updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update depot: $e');
    } finally {
      isUpdating = false;
      update();
    }
  }
}
