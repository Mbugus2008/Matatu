import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:t_matatu/controllers/TypesController.dart';
import 'package:t_matatu/controllers/main.dart';
import 'package:t_matatu/models/expences.dart';
import 'package:t_matatu/models/vehicles/DeportandFuel.dart';
import 'package:t_matatu/models/vehicles/vehicle.dart';
import 'package:t_matatu/providers/db.dart';
import 'package:t_matatu/models/Utils/util.dart';  // Make sure this import is present

import '../../models/TransSummary.dart';
import '../../models/Transaction.dart' as tmatatu;
import '../../network/Apis.dart';
import '../../network/request.dart';
import '../../network/results/results.dart';

class VehiclesController extends GetxController {
  RxList<Vehicles> allVehicles = <Vehicles>[].obs;
  RxList<Vehicles> vehdailycollections = <Vehicles>[].obs;
  RxList<tmatatu.Trans> vehcollections = <tmatatu.Trans>[].obs;
  RxList<Vehicles> vehdailycollectionsf = <Vehicles>[].obs;
  Rx<Vehicles?> Currentvehicle = Rx<Vehicles?>(null);
  
  RxList<Expenses> NRODefects = <Expenses>[].obs;
  final RxBool onroute = false.obs;

  final RxMap<String, bool> _isExpanded = <String, bool>{}.obs;

  void toggle(DepotFuel depotFuel) {
    depotFuel.On_route = !(depotFuel.On_route ?? false);
    Get.find<DepotController>().updateCheckAll();
    update();
  }

  void toggleExpansion(String key) {
    _isExpanded[key] = !(_isExpanded[key] ?? false);
  }

  bool isExpanded(String key) {
    return _isExpanded[key] ?? false;
  }

  @override
  void onInit() {
    super.onInit();
    loadVehicles();
  }

  Future<void> loadVehicles() async {
    try {
      final List<Map<String, dynamic>> maps =
          await db_Provider().getdata(Vehicles.table, Vehicles.columns);
      allVehicles.value = maps.map((row) => Vehicles.fromMap(row)).toList();
      print('Loaded ${allVehicles.length} vehicles');  // Add this debug print
    } catch (e) {
      print('Error loading vehicles: $e');
    }
  }

  Future<void> getvehtrans(String veh, DateTime date) async {
    Get.find<TransTypeController>().vehicleTrantypes.forEach((element) {
      element.Amounttoday = 0;
    });
    Get.find<TransTypeController>().loading.value = true;
    await getcurrvehicle(veh);
    var request = Request(vehicle: veh, date: date);
    await ApiClient()
        .postdata("gettodayvehicletrans", request.toJson())
        .then((r) async {
      if (r.statusCode == 200) {
        Results<tmatatu.Trans> results =
            Results<tmatatu.Trans>.fromJson(r.body, tmatatu.Trans.fromMap);
        if (results.Code == 0) {
          if (results.Contents != null) {
            Get.find<MainController>().vehtrans.value =
                results.Contents as List<tmatatu.Trans>;

            final groupedItems = groupBy(Get.find<MainController>().vehtrans,
                (tmatatu.Trans item) => '${item.Description}');
             // groupedItems.forEach((key, value) {
                //print('Key: $key, Value: $value');
             // });
            final types = [...Get.find<TransTypeController>().vehicleTrantypes];
            //  types.forEach((element) {
              //  print('Type: ${element.Code}-${element.Account}');
             // });
            Get.find<MainController>().vehsummary.value =
                groupedItems.entries.map((entry) {
              final category = entry.key;
              final itemsInCategory = entry.value;
              final totalSum = itemsInCategory.fold(0.0,
                  (sum, item) => sum + num.tryParse(item.Amount.toString())!);
              final expe = types.firstWhereOrNull(
                  (o) => '${o.Name}' == entry.key);
              final bal = (expe == null ? 0 : expe.VehicleAmount)! - totalSum;

              return TransSummary(
                  Type: category,
                  Amount: totalSum,
                  Expected: expe == null ? 0 : expe.VehicleAmount,
                  balance: bal);
            }).toList();
Get.find<MainController>().vehsummary.forEach((element) {
  print('Original:${element.toString()}');
});
            Get.find<TransTypeController>().vehicleTrantypes.forEach((element) {
              print('${element.toString()}');
              TransSummary? summary = Get.find<MainController>()
                  .vehsummary
                  .firstWhereOrNull(
                      (e) => e.Type == '${element.Name}');
              print('Summary:${summary.toString()}');
              if (summary != null) element.Amounttoday = summary.Amount;
           print('${element.toString()}'); });
          }
        }
      }
      Get.find<TransTypeController>().loading.value = false;
    });
    update();
  }

  Future<Vehicles?> getcurrvehicle(String vehicle) async {
    final List<Map<String, dynamic>> maps = await db_Provider().getdata(
        Vehicles.table,
        Vehicles.columns,
        '${Vehicles.col_Vehicle_Number}=?',
        [vehicle]);

    final currentVehicle = maps.map((row) {
      return Vehicles.fromMap(row);
    }).singleOrNull;

    Get.find<VehiclesController>().Currentvehicle.value = currentVehicle;

 await   Get.find<TransTypeController>().vehicleTypes(currentVehicle?.Vehicle_Type);

    return currentVehicle;
  }

  TextStyle summaryAmount() {
    return TextStyle(fontSize: 14, fontWeight: FontWeight.bold);
  }

  TextStyle summarybal() {
    return TextStyle(
        fontSize: 14, fontWeight: FontWeight.w400, color: Colors.blueGrey);
  }

  TextStyle summaryexpected() {
    return TextStyle(fontSize: 14, color: Colors.black87);
  }
  void filterVehicles(String query) {
    vehdailycollections.value = vehdailycollectionsf.where((item) {
      return item.toString().contains(query);
    }).toList();
    update();
  }
  Future<void> refreshVehicleDetails(String? vehicleNumber) async {
    if (vehicleNumber == null) return;

    try {
      // Clear existing collections
      vehcollections.clear();

      // Fetch updated data
      await Vehicles().Daily_Veh_Contributions(getdate(), vehicleNumber);

      // Notify listeners that the data has been updated
      update();
    } catch (e) {
      print('Error refreshing vehicle details: $e');
      // You might want to show an error message to the user here
      Get.snackbar('Error', 'Failed to refresh vehicle details',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

Future<List<Vehicles>> VehicleSuggestions(String pattern) async {
    List<Vehicles> suggestions = [];

    // Get vehicle suggestions first
    var vehiclesController = Get.find<VehiclesController>();
    if (vehiclesController.allVehicles.isEmpty) {
      await vehiclesController.loadVehicles();
    }
    var matchingVehicles = vehiclesController.allVehicles
        .where((vehicle) =>
          vehicle.toString().toLowerCase().contains(pattern.toLowerCase()) ?? false)
        .toList();

      suggestions.addAll(matchingVehicles);

  
    // Sort suggestions to ensure vehicles appear first
    suggestions.sort((a, b) => a.Fleet_No?.compareTo(b.Fleet_No  ?? '') ?? 0);

    return suggestions;
  }


}
