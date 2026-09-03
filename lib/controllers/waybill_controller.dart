// ignore_for_file: public_member_api_docs

import 'package:get/get.dart';
import 'package:t_matatu/models/waybill/waybill.dart';
import 'package:t_matatu/providers/db.dart';

/// Controller for managing Waybill data state and operations
class WaybillController extends GetxController {
  final WaybillService _service = WaybillService();

  final RxList<Waybill> waybills = <Waybill>[].obs;
  final RxList<WaybillTrip> trips = <WaybillTrip>[].obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxBool isLoading = false.obs;
  final Rx<String?> selectedVehicle = Rx<String?>(null);
  final Rx<Waybill?> selectedWaybill = Rx<Waybill?>(null);

  // ─── Load from local DB ──────────────────────────────

  /// Load waybill entries from the local SQLite DB for the selected date.
  /// This is the primary data source — API is only used for sync, not reads.
  Future<void> loadFromLocalDB() async {
    isLoading.value = true;
    try {
      final startOfDay = DateTime(selectedDate.value.year,
          selectedDate.value.month, selectedDate.value.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final db = db_Provider();
      final rows = await db.getdata(
        Waybill.table,
        Waybill.columns,
        '${Waybill.col_Date} >= ? AND ${Waybill.col_Date} < ?',
        [startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch],
      );

      if (rows.isNotEmpty) {
        waybills.assignAll(rows.map((m) => Waybill.fromMap_db(m)).toList());
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
      final result = await _service.getWaybills(selectedDate.value);
      if (result.isNotEmpty) {
        // Merge API results into local DB
        final db = db_Provider();
        for (final wb in result) {
          wb.sent = true;
          await db.insert(Waybill.table, wb);
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
  Future<Waybill?> saveWaybill(Waybill waybill) async {
    isLoading.value = true;
    try {
      // 1. Always save to local DB first
      final saved = await _service.saveWaybill(waybill);

      // 2. Update list immediately
      if (saved != null) {
        final idx = waybills.indexWhere(
            (w) => w.Key == saved.Key || w.Vehicle_No == saved.Vehicle_No);
        if (idx >= 0) {
          waybills[idx] = saved;
        } else {
          waybills.insert(0, saved);
        }
        waybills.refresh();
      }
      return saved;
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Trips ───────────────────────────────────────────

  Future<void> fetchTrips(int waybillId) async {
    isLoading.value = true;
    try {
      final result = await _service.getTrips(waybillId);
      trips.assignAll(result);
    } catch (e) {
      trips.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<WaybillTrip?> saveTrip(WaybillTrip trip) async {
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
