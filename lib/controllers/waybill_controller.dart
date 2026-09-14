// ignore_for_file: public_member_api_docs

import 'package:get/get.dart';
import 'package:t_matatu/models/waybill/waybill.dart';
import 'package:t_matatu/providers/db.dart';
import 'package:t_matatu/providers/logger.dart';

/// Controller for managing Waybill data state and operations
class WaybillController extends GetxController {
  final WaybillService _service = WaybillService();

  void _log(String message) {
    try {
      Get.find<LoggerService>().info('Waybill: $message');
    } catch (_) {
      // Logger not ready — ignore
    }
  }

  void _logError(String message, Object error) {
    try {
      Get.find<LoggerService>().error('Waybill: $message', error: error);
    } catch (_) {
      // Logger not ready — ignore
    }
  }

  final RxList<Waybill> waybills = <Waybill>[].obs;
  final RxList<WaybillTrip> trips = <WaybillTrip>[].obs;

  /// Every waybill entry on the device, newest first (Waybill History screen).
  final RxList<Waybill> allWaybills = <Waybill>[].obs;

  /// Trips across the entries in [waybills] (daily list summary).
  final RxList<WaybillTrip> allTrips = <WaybillTrip>[].obs;

  /// Trips across the entries in [allWaybills] (history screen totals).
  final RxList<WaybillTrip> historyTrips = <WaybillTrip>[].obs;

  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxBool isLoading = false.obs;
  final Rx<String?> selectedVehicle = Rx<String?>(null);
  final Rx<Waybill?> selectedWaybill = Rx<Waybill?>(null);

  // ─── Load from local DB ──────────────────────────────

  /// Loads the waybill entries of [selectedDate] from the local DB.
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

      waybills.assignAll(rows.map((m) => Waybill.fromMap_db(m)).toList());
      _log('loaded ${waybills.length} entries for $startOfDay');
      await _repairOrphans();
      await loadTripTotals();
    } catch (e) {
      // Surface the failure instead of silently showing an empty screen.
      _logError('loadFromLocalDB failed', e);
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Loads every waybill entry on the device, newest first (no date filter).
  Future<void> loadAllFromLocalDB() async {
    isLoading.value = true;
    try {
      final rows = await db_Provider().getdata(Waybill.table, Waybill.columns);

      final loaded = rows.map((m) => Waybill.fromMap_db(m)).toList()
        ..sort((a, b) {
          final ad = a.Date?.millisecondsSinceEpoch ?? 0;
          final bd = b.Date?.millisecondsSinceEpoch ?? 0;
          return bd.compareTo(ad);
        });

      allWaybills.assignAll(loaded);
      _log('loaded ${allWaybills.length} entries (all dates)');
      await _repairOrphans();
      await loadHistoryTripTotals();
    } catch (e) {
      _logError('loadAllFromLocalDB failed', e);
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Loads trips for all waybills of the current list (Target = sum of trip
  /// totals, Actual = sum of amounts received on closed trips).
  /// Public so screens can refresh totals after trips are added or closed.
  Future<void> loadTripTotals() async {
    try {
      allTrips.assignAll(
          await _service.getLocalTripsFor(_idsOf(waybills), _keysOf(waybills)));
      _log('loaded ${allTrips.length} trips for ${waybills.length} entries');
    } catch (e) {
      _logError('loadTripTotals failed', e);
    }
  }

  /// Loads trip totals for the entries shown on the Waybill History screen.
  Future<void> loadHistoryTripTotals() async {
    try {
      historyTrips.assignAll(await _service.getLocalTripsFor(
          _idsOf(allWaybills), _keysOf(allWaybills)));
      _log('loaded ${historyTrips.length} trips for '
          '${allWaybills.length} history entries');
    } catch (e) {
      _logError('loadHistoryTripTotals failed', e);
    }
  }

  List<int> _idsOf(List<Waybill> list) =>
      list.map((w) => w.Entry_No).whereType<int>().toList();

  /// Adopts trips that were saved without a waybill link, so they become
  /// visible in the trips list, and converts crew names to crew numbers for
  /// entries saved by older builds (BC only accepts the 10-char crew number).
  Future<void> _repairOrphans() async {
    try {
      final repaired = await _service.repairOrphanTrips();
      if (repaired > 0) {
        _log('linked $repaired orphan trip(s) to their waybill');
      }
      final normalized = await _service.normalizeCrewNumbers();
      if (normalized > 0) {
        _log('normalized crew numbers on $normalized waybill(s)');
      }
    } catch (e) {
      _logError('local waybill repair failed', e);
    }
  }

  List<String> _keysOf(List<Waybill> list) => list
      .map((w) => w.Key)
      .whereType<String>()
      .where((k) => k.isNotEmpty)
      .toList();

  /// Trips belonging to one entry — matched by BC entry number or local key.
  List<WaybillTrip> tripsFor(Waybill wb) {
    return historyTrips.where((t) {
      if (wb.Entry_No != null && t.Weign_Bridge_id == wb.Entry_No) return true;
      return wb.Key != null && t.Waybill_Key == wb.Key;
    }).toList();
  }

  /// Two-way sync: pushes local entries/trips that BC has not accepted yet,
  /// then pulls the day's entries and merges them. Used by the Sync button and
  /// by pull-to-refresh on the waybill screens.
  Future<void> syncFromAPI() async {
    isLoading.value = true;
    try {
      // 1. Push pending work first, so local entries get their BC entry number
      //    and the trips waiting on them can follow.
      final pushedWaybills = await _service.syncPendingWaybills();
      final pushedTrips = await _service.syncPendingWaybillTrips();
      _log('pushed $pushedWaybills waybill(s), $pushedTrips trip(s)');

      // 2. Pull the day's entries from BC.
      final result = await _service.getWaybills(DateTime.now());
      _log('API returned ${result.length} entries');
      final db = db_Provider();
      for (final wb in result) {
        wb.sent = wb.Entry_No != null;
        await db.insert(Waybill.table, wb);
      }
    } catch (e) {
      _logError('syncFromAPI failed', e);
    } finally {
      // Always re-read local DB so the screen reflects merged + pending rows,
      // even when BC has no entries for the date.
      try {
        await loadFromLocalDB();
      } catch (_) {
        // Already logged in loadFromLocalDB
      }
      await loadTripTotals();
      // Keep the history screen in step with the same sync.
      try {
        await loadAllFromLocalDB();
      } catch (_) {
        // Already logged in loadAllFromLocalDB
      }
      isLoading.value = false;
    }
  }

  // ─── Save ────────────────────────────────────────────

  /// The existing entry for this vehicle on this day, if one exists.
  /// Business rule: one waybill per vehicle per day — trips are unlimited.
  Future<Waybill?> findEntryForVehicle({
    String? vehicleNo,
    String? fleetNo,
    required DateTime date,
    String? excludeKey,
  }) =>
      _service.findEntryForVehicle(
        vehicleNo: vehicleNo,
        fleetNo: fleetNo,
        date: date,
        excludeKey: excludeKey,
      );

  /// Crew number for a name (or an already-entered number), from the local
  /// crew list. Used when a waybill is saved.
  Future<String?> resolveCrewNo(String? nameOrNumber, {String? vehicle}) =>
      _service.resolveCrewNo(nameOrNumber, vehicle: vehicle);

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

  Future<void> fetchTrips(int? waybillId, {String? waybillKey}) async {
    isLoading.value = true;
    try {
      final result = await _service.getTrips(waybillId, waybillKey: waybillKey);
      trips.assignAll(result);
      _log('fetchTrips entryNo=$waybillId key=$waybillKey '
          '-> ${result.length} trips');
    } catch (e) {
      _logError('fetchTrips failed (entryNo=$waybillId key=$waybillKey)', e);
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

  /// Safe reload for the daily screen — never throws.
  Future<void> reload() async {
    try {
      await loadFromLocalDB();
    } catch (_) {
      // Already logged in loadFromLocalDB
    }
    await loadTripTotals();
  }

  /// Safe reload for the Waybill History screen — never throws.
  Future<void> reloadAll() async {
    try {
      await loadAllFromLocalDB();
    } catch (_) {
      // Already logged in loadAllFromLocalDB
    }
    await loadHistoryTripTotals();
  }

  @override
  void onInit() {
    super.onInit();
    reload();
  }
}
