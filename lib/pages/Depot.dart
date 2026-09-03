import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:t_matatu/controllers/vehicles/vehicles.dart';
import 'package:t_matatu/models/Utils/util.dart';
import 'package:t_matatu/models/expenses/expenses.dart';
import 'package:t_matatu/models/vehicles/DeportandFuel.dart';
import 'package:t_matatu/models/vehicles/vehicle.dart';
import 'package:t_matatu/pages/crew.dart';

class Depot extends StatefulWidget {
  const Depot({super.key});

  @override
  State<Depot> createState() => _DepotState();
}

class _DepotState extends State<Depot> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _fetchData();
    }
  }

  void _fetchData() {
    DepotFuel().getNRODefects();
    DepotFuel().getdata(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DepotController>(
      init: Get.find<DepotController>(),
      builder: (dp) => Stack(
        children: [
          Column(
            children: [
              _buildDateSelector(),
              _buildSearchField(),
              _buildActiveVehiclesInfo(dp),
              Expanded(child: _buildVehicleList(dp)),
              const SizedBox(height: 84), // keep list clear of the FAB
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Obx(() {
              final isUpdating = dp.updating.value;
              final progress = dp.updateProgress.value;
              final total = dp.updateTotal.value;
              return FloatingActionButton.extended(
                onPressed: isUpdating ? null : update,
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                icon: isUpdating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  isUpdating
                      ? (total > 0
                          ? 'Updating $progress/$total...'
                          : 'Updating...')
                      : 'Update',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 18, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd-MMM-yyyy').format(_selectedDate),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _fetchData,
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Get'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: TextFormField(
        onChanged: (value) {
          Get.find<DepotController>().filterDepotTrans(value.toUpperCase());
          if (value.isEmpty) {
            // Optionally, force a refresh or reset the list if the search field is empty
            //Get.find<DepotController>().depottrans.assignAll(Get.find<DepotController>().depottrans1); // You might need to implement this method
          }
        },
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12),
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search_off, color: Colors.blue, size: 18),
          floatingLabelAlignment: FloatingLabelAlignment.center,
          labelText: 'Find Vehicle',
          labelStyle: TextStyle(fontSize: 12),
          contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 8),
        ),
      ),
    );
  }

  Widget _buildActiveVehiclesInfo(DepotController dp) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Obx(() {
            final activeCount = Get.find<DepotController>()
                .depottrans
                .where((p0) => p0.On_route == true)
                .length;
            final totalCount = Get.find<DepotController>().depottrans.length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Vehicles',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '$activeCount / $totalCount',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          }),
          Obx(() => Switch(
                value: dp.checkall.value,
                onChanged: dp.checkallvehicles,
                activeColor: Colors.white,
                activeTrackColor: Colors.green.shade300,
              )),
        ],
      ),
    );
  }

  Widget _buildVehicleList(DepotController depotController) {
    return Obx(() {
      if (depotController.depottrans.isEmpty) {
        return Center(
            child:
                Text('No vehicles available', style: TextStyle(fontSize: 12)));
      }
      return ListView.builder(
        itemCount: depotController.depottrans.length,
        itemBuilder: (context, index) => Container(
            child: _buildVehicleCard(depotController.depottrans[index])),
      );
    });
  }

  Widget _buildVehicleCard(DepotFuel depotFuel) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildVehicleHeader(depotFuel),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildCrewInfo(depotFuel)),
                SizedBox(width: 8),
                Expanded(
                    flex: 3,
                    child: _buildDefectAndDescriptionFields(depotFuel)),
                SizedBox(width: 8),
                Expanded(flex: 1, child: _buildOnRouteCheckbox(depotFuel)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleHeader(DepotFuel depotFuel) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${depotFuel.Fleet ?? 'N/A'} | ${depotFuel.Vehicle ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Spacer(),
                Text(
                  '${vehicle_type_desc.desc[depotFuel.Capacity]}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrewInfo(DepotFuel depotFuel) {
    return InkWell(
      onTap: () => setvehicle(depotFuel.Vehicle ?? '', depotFuel),
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[200]!, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCrewMemberInfo(
                'Driver', depotFuel.Driver, depotFuel.Driver_Name),
            SizedBox(height: 8),
            _buildCrewMemberInfo(
                'Conductor', depotFuel.Conductor, depotFuel.Conductor_Name),
          ],
        ),
      ),
    );
  }

  Widget _buildCrewMemberInfo(String role, String? id, String? name) {
    final hasInfo = !id.isNullOrEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          role,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: hasInfo ? Colors.green[50] : Colors.red[50],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasInfo) ...[
                Text(
                  id!,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  name ?? '',
                  style: TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ] else
                Text(
                  'No $role',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDefectAndDescriptionFields(DepotFuel depotFuel) {
    return Column(
      children: [
        _buildDefectField(depotFuel),
        SizedBox(height: 8), // Add some spacing between the fields
        _buildDescriptionField(depotFuel),
      ],
    );
  }

  Widget _buildDefectField(DepotFuel depotFuel) {
    TextEditingController? internal;
    if (depotFuel.On_route == null || depotFuel.On_route == false) {
      return Container(
        width: 150,
        child: TypeAheadField<Expenses>(
          suggestionsCallback: (pattern) async {
            return suggestionsCallback(pattern);
          },
          itemBuilder: (context, Expenses nro) {
            return ListTile(
              title: Text(nro.Code.toString()),
              subtitle: Text(nro.Description.toString()),
            );
          },
          onSelected: (Expenses nro) {
            depotFuel.Nro_Defects = nro.Code;
            depotFuel.Nro_Defects_editor.text = nro.Code.toString();
            depotFuel.dirty = true;
            // flutter_typeahead does not update its own controller on pick,
            // so set it explicitly to show the chosen defect.
            internal?.text = nro.Code.toString();
          },
          builder: (context, controller, focusNode) {
            internal = controller;
            // Prefill the typeahead's own controller if the editor has a value,
            // so previously picked defects still show after rebuilds.
            if (controller.text.isEmpty &&
                depotFuel.Nro_Defects_editor.text.isNotEmpty) {
              controller.text = depotFuel.Nro_Defects_editor.text;
            }
            return TextField(
              controller: controller,
              focusNode: focusNode,
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(
                contentPadding:
                    EdgeInsets.symmetric(vertical: 0.0, horizontal: 10.0),
                hintText: 'Defect',
              ),
              onChanged: (value) {
                depotFuel.Nro_Defects = value;
                depotFuel.Nro_Defects_editor.text = value;
                depotFuel.dirty = true;
              },
            );
          },
        ),
      );
    } else {
      return SizedBox.shrink(); // Return an empty widget if On_route is true
    }
  }

  Widget _buildDescriptionField(DepotFuel depotFuel) {
    print("Description ${depotFuel.Descrition}");
    return Visibility(
      visible: depotFuel.On_route == null || depotFuel.On_route == false,
      child: Container(
        width: 150,
        child: TextField(
          controller: depotFuel.desc_editor,
          style: const TextStyle(fontSize: 12),
          decoration: const InputDecoration(
            contentPadding:
                EdgeInsets.symmetric(vertical: 0.0, horizontal: 10.0),
            hintText: 'Description',
          ),
          onChanged: (String? newValue) {
            print("New description: $newValue");
            depotFuel.Descrition = newValue ?? '';
            depotFuel.desc_editor.text = newValue ?? '';
            depotFuel.dirty = true;
          },
        ),
      ),
    );
  }

  Widget _buildOnRouteCheckbox(DepotFuel depotFuel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              Get.find<VehiclesController>().toggle(depotFuel);
              depotFuel.From = getdatetime();
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Checkbox(
                value: depotFuel.On_route ?? false,
                onChanged: (bool? newValue) {
                  Get.find<VehiclesController>().toggle(depotFuel);
                  depotFuel.From = getdatetime();
                },
              ),
            ),
          ),
        ),
        // Expanded(
        //   child: GestureDetector(
        //     onTap: () {
        //       depotFuel.Run_Back = !(depotFuel.Run_Back ?? false);
        //       Get.find<DepotController>().update();
        //     },
        //     child: Container(
        //       padding: EdgeInsets.symmetric(horizontal: 8),
        //       child: Row(
        //         children: [
        //           Checkbox(
        //             value: depotFuel.Run_Back ?? false,
        //             onChanged: (bool? newValue) {
        //               depotFuel.Run_Back = newValue;
        //               Get.find<DepotController>().update();
        //             },
        //           ),
        //           Text('Run Back', style: TextStyle(fontSize: 12)),
        //         ],
        //       ),
        //     ),
        //   ),
        // ),
      ],
    );
  }

  void update() {
    final depots = Get.find<DepotController>().depottrans;

    // Enforce: every modified vehicle must be ticked "On route" OR have a defect.
    final invalid = depots
        .where((d) =>
            d.dirty &&
            d.On_route != true &&
            (d.Nro_Defects == null || d.Nro_Defects!.trim().isEmpty))
        .toList();

    if (invalid.isNotEmpty) {
      final vehicles = invalid.map((d) => d.Vehicle ?? '?').take(5).join(', ');
      Get.snackbar(
        'Validation',
        'Tick "On route" or select a defect for: $vehicles${invalid.length > 5 ? ' (+${invalid.length - 5} more)' : ''}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    DepotFuel().updatedepot(depots);
  }

  Future<void> setvehicle(String vehicle, DepotFuel depotFuel) async {
    final veh = await VehiclesController().getcurrvehicle(vehicle);
    final result = await Get.to(() => CrewAssignment(vehicle: veh));
    if (result != null) {
      Vehicles v = result;
      depotFuel.Driver = v.Driver?.No;
      depotFuel.Driver_Name = v.Driver?.Name;
      depotFuel.Conductor = v.Conductor?.No;
      depotFuel.Conductor_Name = v.Conductor?.Name;
      depotFuel.dirty = true;
      Get.find<DepotController>().update();
    }
  }

  Future<List<Expenses>> suggestionsCallback(String pattern) async {
    return Get.find<VehiclesController>().NRODefects.where((product) {
      final nameLower = product.toString().toLowerCase();
      return nameLower.contains(pattern.toLowerCase());
    }).toList();
  }
}

class LabeledCheckbox extends StatelessWidget {
  const LabeledCheckbox({
    Key? key,
    required this.label,
    required this.padding,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  final String label;
  final EdgeInsets padding;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onChanged(!value);
      },
      child: Padding(
        padding: padding,
        child: Row(
          children: <Widget>[
            Checkbox(
              value: value,
              onChanged: (bool? newValue) {
                onChanged(newValue ?? false);
              },
            ),
            Expanded(child: Text(label)),
          ],
        ),
      ),
    );
  }
}
