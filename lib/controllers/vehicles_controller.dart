import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';
import 'package:t_matatu/controllers/TypesController.dart';
import 'package:t_matatu/controllers/main.dart';
import 'package:t_matatu/models/TransSummary.dart';
import 'package:t_matatu/models/Transaction.dart' as tmatatu;
import 'package:t_matatu/models/Utils/util.dart';
import 'package:t_matatu/models/expences.dart';
import 'package:t_matatu/models/trantypes.dart';
import 'package:t_matatu/models/vehicles/DeportandFuel.dart';
import 'package:t_matatu/models/vehicles/vehicle.dart';
import 'package:t_matatu/network/Apis.dart';
import 'package:t_matatu/network/request.dart';
import 'package:t_matatu/network/results/results.dart';
import 'package:t_matatu/providers/db.dart';

class VehiclesController extends GetxController {
  VehiclesController({db_Provider? dbProvider})
      : _dbProviderOverride = dbProvider;

  final db_Provider? _dbProviderOverride;

  db_Provider get _dbProvider =>
      _dbProviderOverride ?? Get.find<db_Provider>();

  final RxList<Vehicles> allVehicles = <Vehicles>[].obs;
  final RxList<Vehicles> vehdailycollections = <Vehicles>[].obs;
  final RxList<tmatatu.Trans> vehcollections = <tmatatu.Trans>[].obs;
  final RxList<Vehicles> vehdailycollectionsf = <Vehicles>[].obs;
  final Rx<Vehicles?> Currentvehicle = Rx<Vehicles?>(null);
  String _lastFilterQuery = '';

  String get lastFilterQuery => _lastFilterQuery;

  final RxList<Expenses> NRODefects = <Expenses>[].obs;
  final RxBool onroute = false.obs;
  final RxMap<String, bool> _isExpanded = <String, bool>{}.obs;

  List<Vehicles> get vehicles => List<Vehicles>.unmodifiable(allVehicles);

  @override
  void onInit() {
    super.onInit();
    loadVehicles();
  }

  Future<void> loadVehicles() async {
    try {
      final List<Map<String, dynamic>> maps =
          await _dbProvider.getdata(Vehicles.table, Vehicles.columns);
      allVehicles.value = maps.map(Vehicles.fromMap).toList();
    } catch (e) {
      debugPrint('Error loading vehicles: $e');
    }
  }

  Future<void> fetchVehicles() async {
    await loadVehicles();
  }

  Future<List<Vehicles>> searchVehicles(String query) async {
    final String trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return <Vehicles>[];
    }

    if (allVehicles.isEmpty) {
      await loadVehicles();
    }

    final String lowerQuery = trimmedQuery.toLowerCase();

    return allVehicles.where((Vehicles vehicle) {
      final String vehicleNumber = (vehicle.Vehicle_Number ?? '').toLowerCase();
      final String fleetNumber = (vehicle.Fleet_No ?? '').toLowerCase();
      return vehicleNumber.contains(lowerQuery) ||
          fleetNumber.contains(lowerQuery);
    }).toList();
  }

  Future<List<Vehicles>> getVehicleSuggestions(String query) async {
    final List<Vehicles> matches = await searchVehicles(query);
    return matches.take(5).toList();
  }

  Future<void> addVehicle(Vehicles vehicle) async {
    try {
      await _dbProvider.insert(Vehicles.table, vehicle);
      allVehicles.add(vehicle);
      filterVehicles(_lastFilterQuery);
      Get.snackbar('Success', 'Vehicle added successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to add vehicle: $e');
      rethrow;
    }
  }

  Future<void> updateVehicle(Vehicles vehicle) async {
    try {
      await _dbProvider.insert(Vehicles.table, vehicle);
      final int index = allVehicles.indexWhere(
          (Vehicles existing) => existing.Vehicle_Number == vehicle.Vehicle_Number);
      if (index != -1) {
        allVehicles[index] = vehicle;
      } else {
        allVehicles.add(vehicle);
      }
      filterVehicles(_lastFilterQuery);
      Get.snackbar('Success', 'Vehicle updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update vehicle: $e');
      rethrow;
    }
  }

  Future<void> deleteVehicle(String vehicleNumber) async {
    try {
      final Database db = await _dbProvider.database;
      await db.delete(
        Vehicles.table,
        where: '${Vehicles.col_Vehicle_Number} = ?',
        whereArgs: <Object?>[vehicleNumber],
      );
      allVehicles.removeWhere(
          (Vehicles vehicle) => vehicle.Vehicle_Number == vehicleNumber);
      filterVehicles(_lastFilterQuery);
      Get.snackbar('Success', 'Vehicle deleted successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete vehicle: $e');
      rethrow;
    }
  }

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

  Future<void> getvehtrans(String veh, DateTime date) async {
    Get.find<TransTypeController>().vehicleTrantypes.forEach(
      (TranTypes element) {
        element.Amounttoday = 0;
      },
    );
    Get.find<TransTypeController>().loading.value = true;
    await getcurrvehicle(veh);
    final Request request = Request(vehicle: veh, date: date);
    await ApiClient()
        .postdata('gettodayvehicletrans', request.toJson())
        .then((response) async {
      if (response.statusCode == 200) {
        final Results<tmatatu.Trans> results = Results<tmatatu.Trans>.fromJson(
          response.body,
          tmatatu.Trans.fromMap,
        );
        if (results.Code == 0 && results.Contents != null) {
          Get.find<MainController>().vehtrans.value =
              results.Contents as List<tmatatu.Trans>;

          final Map<String, List<tmatatu.Trans>> groupedItems =
              groupBy(
            Get.find<MainController>().vehtrans,
            (tmatatu.Trans item) => '${item.Description}',
          );

          final List<TranTypes> types =
              <TranTypes>[...Get.find<TransTypeController>().vehicleTrantypes];

          Get.find<MainController>().vehsummary.value = groupedItems.entries
              .map((MapEntry<String, List<tmatatu.Trans>> entry) {
            final String category = entry.key;
            final List<tmatatu.Trans> itemsInCategory = entry.value;
            final double totalSum = itemsInCategory.fold<double>(
              0,
              (double sum, tmatatu.Trans item) =>
                  sum + num.tryParse(item.Amount.toString())!.toDouble(),
            );
            final TranTypes? expe = types.firstWhereOrNull(
              (TranTypes type) => '${type.Name}' == category,
            );
            final double expected = expe?.VehicleAmount ?? 0;
            final double balance = expected - totalSum;

            return TransSummary(
              Type: category,
              Amount: totalSum,
              Expected: expected,
              balance: balance,
            );
          }).toList();

          Get.find<TransTypeController>().vehicleTrantypes.forEach(
            (TranTypes element) {
              final TransSummary? summary =
                  Get.find<MainController>().vehsummary.firstWhereOrNull(
                        (TransSummary e) => e.Type == '${element.Name}',
                      );
              if (summary != null) {
                element.Amounttoday = summary.Amount;
              }
            },
          );
        }
      }
      Get.find<TransTypeController>().loading.value = false;
    });
    update();
  }

  Future<Vehicles?> getcurrvehicle(String vehicleNumber) async {
    final VehiclesController controller =
        Get.isRegistered<VehiclesController>()
            ? Get.find<VehiclesController>()
            : this;

    final List<Map<String, dynamic>> maps = await _dbProvider.getdata(
      Vehicles.table,
      Vehicles.columns,
      '${Vehicles.col_Vehicle_Number}=?',
      <Object?>[vehicleNumber].cast<Object>(),
    );

    final Vehicles? currentVehicle =
        maps.map(Vehicles.fromMap).singleOrNull;

    controller.Currentvehicle.value = currentVehicle;

    await Get.find<TransTypeController>()
        .vehicleTypes(currentVehicle?.Vehicle_Type);

    return currentVehicle;
  }

  TextStyle summaryAmount() {
    return const TextStyle(fontSize: 14, fontWeight: FontWeight.bold);
  }

  TextStyle summarybal() {
    return const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: Colors.blueGrey,
    );
  }

  TextStyle summaryexpected() {
    return const TextStyle(fontSize: 14, color: Colors.black87);
  }

  Future<void> refreshDailyCollections() async {
    try {
      await Vehicles().Daily_Contributions(getdate());
      filterVehicles(_lastFilterQuery);
    } catch (e) {
      debugPrint('Error refreshing vehicle list: $e');
      Get.snackbar(
        'Error',
        'Failed to refresh vehicle list',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void filterVehicles(String query) {
    _lastFilterQuery = query;
    final String lowerQuery = query.toLowerCase();
    vehdailycollections.value = vehdailycollectionsf.where((Vehicles item) {
      return item.toString().toLowerCase().contains(lowerQuery);
    }).toList();
    update();
  }

  Future<void> refreshVehicleDetails(String? vehicleNumber) async {
    if (vehicleNumber == null) {
      return;
    }

    try {
      vehcollections.clear();
      await Vehicles().Daily_Veh_Contributions(getdate(), vehicleNumber);
      update();
    } catch (e) {
      debugPrint('Error refreshing vehicle details: $e');
      Get.snackbar(
        'Error',
        'Failed to refresh vehicle details',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<List<Vehicles>> VehicleSuggestions(String pattern) async {
    final VehiclesController controller =
        Get.isRegistered<VehiclesController>()
            ? Get.find<VehiclesController>()
            : this;

    if (pattern.trim().isEmpty) {
      return <Vehicles>[];
    }

    if (controller.allVehicles.isEmpty) {
      await controller.loadVehicles();
    }

    final String lowerPattern = pattern.toLowerCase();
    final List<Vehicles> suggestions = controller.allVehicles
        .where(
          (Vehicles vehicle) =>
              vehicle.toString().toLowerCase().contains(lowerPattern),
        )
        .toList();

    suggestions.sort(
      (Vehicles a, Vehicles b) =>
          (a.Fleet_No ?? '').compareTo(b.Fleet_No ?? ''),
    );

    return suggestions;
  }
}
