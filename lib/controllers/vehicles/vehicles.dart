import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:t_matatu/controllers/TypesController.dart';
import 'package:t_matatu/controllers/main.dart';
import 'package:t_matatu/models/Utils/util.dart'; // Make sure this import is present
import 'package:t_matatu/models/expenses/expenses.dart';
import 'package:t_matatu/models/trantypes.dart';
import 'package:t_matatu/models/vehicles/DeportandFuel.dart';
import 'package:t_matatu/models/vehicles/vehicle.dart';
import 'package:t_matatu/providers/db.dart';

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

  /// Ticket of the newest "today" load — see [getvehtrans]. Only the newest
  /// load may write the shared today-state; older responses are discarded.
  int _vehtransTicket = 0;

  void toggle(DepotFuel depotFuel) {
    depotFuel.On_route = !(depotFuel.On_route ?? false);
    depotFuel.dirty = true;
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
      print('Loaded ${allVehicles.length} vehicles'); // Add this debug print
    } catch (e) {
      print('Error loading vehicles: $e');
    }
  }

  Future<void> getvehtrans(String veh, DateTime date) async {
    // Selecting another vehicle while a load is still in flight used to let
    // the previous vehicle's response land on the new vehicle's screen (its
    // "Today" amounts and summaries stuck around). Every load takes a
    // ticket; only the newest one may write the shared state.
    final ticket = ++_vehtransTicket;
    final typeController = Get.find<TransTypeController>();
    final mainController = Get.find<MainController>();

    // Fresh slate for the newly selected vehicle — no residue from the
    // previous one while its data loads.
    for (final element in typeController.vehicleTrantypes) {
      element.Amounttoday = 0;
    }
    mainController.vehtrans.clear();
    mainController.vehsummary.clear();
    typeController.loading.value = true;

    try {
      // Inside the try so a failed rebuild still clears [loading] in the
      // finally below — the spinner must never stay stuck.
      await getcurrvehicle(veh, ticket: ticket);
      if (ticket != _vehtransTicket) return; // a newer selection superseded us

      var request = Request(vehicle: veh, date: date);
      final r =
          await ApiClient().postdata("gettodayvehicletrans", request.toJson());
      if (ticket != _vehtransTicket) return; // stale response — discard
      if (r.statusCode == 200) {
        Results<tmatatu.Trans> results =
            Results<tmatatu.Trans>.fromJson(r.body, tmatatu.Trans.fromMap);
        if (results.Code == 0) {
          if (results.Contents != null) {
            mainController.vehtrans.value =
                results.Contents as List<tmatatu.Trans>;

            final groupedItems = groupBy(mainController.vehtrans,
                (tmatatu.Trans item) => '${item.Description}');
            final types = [...typeController.vehicleTrantypes];
            mainController.vehsummary.value = groupedItems.entries.map((entry) {
              final category = entry.key;
              final itemsInCategory = entry.value;
              final totalSum = itemsInCategory.fold(0.0,
                  (sum, item) => sum + num.tryParse(item.Amount.toString())!);
              // Match the group to its type by the transaction code — the
              // same key the rest of the app uses. Crew savings descriptions
              // additionally carry the crew number in brackets.
              final expe = TranTypes.typeForTransaction(
                  types, itemsInCategory.first.Type, entry.key);
              final bal = (expe == null ? 0 : expe.VehicleAmount)! - totalSum;

              return TransSummary(
                  Type: category,
                  Amount: totalSum,
                  Expected: expe == null ? 0 : expe.VehicleAmount,
                  balance: bal,
                  agents: TransSummary.distinctAgents(
                      itemsInCategory.map((e) => e.Agent_Code)));
            }).toList();
            // Today's collections per type: sum every transaction row by
            // its type code, so amounts already captured count against the
            // type's balance and Distribute does not fill them again.
            for (final element in typeController.vehicleTrantypes) {
              element.Amounttoday = 0;
            }
            for (final trans in mainController.vehtrans) {
              final type = TranTypes.typeForTransaction(
                  typeController.vehicleTrantypes,
                  trans.Type,
                  trans.Description);
              if (type == null) continue;
              type.Amounttoday = (type.Amounttoday ?? 0) + (trans.Amount ?? 0);
            }
          }
        }
      }
    } catch (_) {
      // Network or vehicle-rebuild hiccup: the slate stays clean; the next
      // selection reloads.
    } finally {
      if (ticket == _vehtransTicket) {
        typeController.loading.value = false;
        update();
      }
    }
  }

  /// Loads [vehicle] into [Currentvehicle] and rebuilds the vehicle's type
  /// list. [ticket] (used by [getvehtrans]) keeps a superseded load from
  /// overwriting the state of a vehicle the user selected after this one.
  Future<Vehicles?> getcurrvehicle(String vehicle, {int? ticket}) async {
    final List<Map<String, dynamic>> maps = await db_Provider().getdata(
        Vehicles.table,
        Vehicles.columns,
        '${Vehicles.col_Vehicle_Number}=?',
        [vehicle]);

    // A newer selection superseded this load while the DB read was in
    // flight — leave the newer vehicle's state alone.
    if (ticket != null && ticket != _vehtransTicket) return null;

    final currentVehicle = maps.map((row) {
      return Vehicles.fromMap(row);
    }).singleOrNull;

    Get.find<VehiclesController>().Currentvehicle.value = currentVehicle;

    await Get.find<TransTypeController>()
        .vehicleTypes(currentVehicle?.Vehicle_Type);

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

  /// Re-pulls today's per-vehicle figures for the home list. Completes when
  /// the request has been answered, so pull-to-refresh keeps spinning until
  /// the figures are actually fresh.
  Future<void> refreshDailyCollections() async {
    await Vehicles().Daily_Contributions(getdate());
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
            vehicle.toString().toLowerCase().contains(pattern.toLowerCase()) ??
            false)
        .toList();

    suggestions.addAll(matchingVehicles);

    // Sort suggestions to ensure vehicles appear first
    suggestions.sort((a, b) => a.Fleet_No?.compareTo(b.Fleet_No ?? '') ?? 0);

    return suggestions;
  }
}
