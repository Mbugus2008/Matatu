import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get.dart';
import 'package:t_matatu/controllers/vehicles/vehicles.dart';
import 'package:t_matatu/models/Utils/util.dart';
import 'package:t_matatu/models/expenses/expenses.dart';
import 'package:t_matatu/models/vehicles/DeportandFuel.dart';
import 'package:t_matatu/models/vehicles/vehicle.dart';
import 'package:t_matatu/pages/crew.dart';

class Depot extends StatelessWidget {
  const Depot({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Depot Statistics', style: TextStyle(fontSize: 16)),
      //   elevation: 4,
      //   centerTitle: true,
      //   toolbarHeight: 40,
      // ),
      body: GetBuilder<DepotController>(
        init: Get.find<DepotController>(),
        builder: (dp) => Column(
          children: [
            _buildSearchField(),
            _buildActiveVehiclesInfo(dp),
            Expanded(child: _buildVehicleList(dp)),
            _buildUpdateButton(dp),
          ],
        ),
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
          },
          builder: (context, controller, focusNode) {
            return TextField(
              controller: depotFuel.Nro_Defects_editor,
              focusNode: focusNode,
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(
                contentPadding:
                    EdgeInsets.symmetric(vertical: 0.0, horizontal: 10.0),
                hintText: 'Defect',
              ),
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
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Checkbox(
                    value: depotFuel.On_route ?? false,
                    onChanged: (bool? newValue) {
                      Get.find<VehiclesController>().toggle(depotFuel);
                      depotFuel.From = getdatetime();
                    },
                  ),
                  //Text('On Route', style: TextStyle(fontSize: 12)),
                ],
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

  Widget _buildUpdateButton(DepotController dp) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Obx(() {
        final isUpdating = dp.updating.value;
        return ElevatedButton(
          onPressed: isUpdating ? null : update,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: isUpdating
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                )
              : Text('Update', style: TextStyle(fontSize: 14)),
        );
      }),
    );
  }

  void update() {
    DepotFuel().updatedepot(Get.find<DepotController>().depottrans);
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
