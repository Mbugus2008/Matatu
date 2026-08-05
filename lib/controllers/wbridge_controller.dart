// ignore_for_file: public_member_api_docs

import 'package:get/get.dart';
import 'package:t_matatu/models/weighbridge/wbridge.dart';
import 'package:t_matatu/providers/db.dart';

/// Controller for managing Weigh Bridge data state and operations
class WBridgeController extends GetxController {
  final WBridgeService _service = WBridgeService();

  final RxList<WBridge> wbridges = <WBridge>[].obs;
  final RxList<WbridgeTrip> trips = <WbridgeTrip>[].obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxBool isLoading = false.obs;
  final Rx<String?> selectedVehicle = Rx<String?>(null);
  final Rx<WBridge?> selectedWBridge = Rx<WBridge?>(null);

  // ─── Load from local DB ──────────────────────────────

  /// Load weigh bridge entries from the local SQLite DB for the selected date.
  /// This is the primary data source — API is only used for sync, not reads.
  Future<void> loadFromLocalDB() async {
    isLoading.value = true;
    try {
      final startOfDay = DateTime(selectedDate.value.year,
          selectedDate.value.month, selectedDate.value.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final db = db_Provider();
      final rows = await db.getdata(
        WBridge.table,
        WBridge.columns,
        '${WBridge.col_Date} >= ? AND ${WBridge.col_Date} < ?',
        [startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch],
      );

      if (rows.isNotEmpty) {
        wbridges.assignAll(rows.map((m) => WBridge.fromMap_db(m)).toList());
      }
    } catch (_) {
      // Keep existing data on failure
    } finally {
      isLoading.value = false;
    }
  }

  /// Try to fetch from API and merge into local DB + list.
  /// Called on pull-to-refresh or manual sync.
  Future<void> syncFromAPI() async {
    isLoading.value = true;
    try {
      final result = await _service.getWBridges(selectedDate.value);
      if (result.isNotEmpty) {
        // Merge API results into local DB
        final db = db_Provider();
        for (final wb in result) {
          wb.sent = true;
          await db.insert(WBridge.table, wb);
        }
        // Reload from local DB for consistent view
        await loadFromLocalDB();
      }
    } catch (_) {
      // API failed — still have local data
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Save ────────────────────────────────────────────

  /// Save to local DB first, then attempt background API sync.
  /// Updates the list immediately for instant UI feedback.
  Future<WBridge?> saveWBridge(WBridge wbridge) async {
    isLoading.value = true;
    try {
      // 1. Always save to local DB first
      final saved = await _service.saveWBridge(wbridge);

      // 2. Update list immediately
      if (saved != null) {
        final idx = wbridges.indexWhere(
            (w) => w.Key == saved.Key || w.Vehicle_No == saved.Vehicle_No);
        if (idx >= 0) {
          wbridges[idx] = saved;
        } else {
          wbridges.insert(0, saved);
        }
        wbridges.refresh();
      }
      return saved;
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Trips ───────────────────────────────────────────

  Future<void> fetchTrips(int weighBridgeId) async {
    isLoading.value = true;
    try {
      final result = await _service.getTrips(weighBridgeId);
      trips.assignAll(result);
    } catch (e) {
      trips.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<WbridgeTrip?> saveTrip(WbridgeTrip trip) async {
    isLoading.value = true;
    try {
      final saved = await _service.saveTrip(trip);
      return saved;
    } finally {
      isLoading.value = false;
    }
  }

  double calculateShortage(double target, double actual) {
    return target - actual;
  }

  double calculateTripTotal(double fareAmount, int pax) {
    return fareAmount * pax;
  }

  @override
  void onInit() {
    super.onInit();
    loadFromLocalDB();
  }
}
