import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:t_matatu/models/Transaction.dart' as tmatatu;
import 'package:t_matatu/models/Utils/util.dart';
import 'package:t_matatu/providers/db.dart';

import '../models/waybill_revenue_entry.dart';

class WaybillRevenueRepository extends GetxService {
  static const String boxName = 'waybill_revenue_entries';

  late Box<WaybillRevenueEntry> _box;
  Future<WaybillRevenueRepository> init() async {
    _box = await Hive.openBox<WaybillRevenueEntry>(boxName);
    return this;
  }

  Future<WaybillRevenueEntry> saveEntry(WaybillRevenueEntry entry) async {
    await _box.put(entry.id, entry);
    return entry;
  }

  List<WaybillRevenueEntry> getEntries() {
    return _box.values.toList(growable: false);
  }

  List<WaybillRevenueEntry> getPendingEntries() {
    return _box.values
        .where((WaybillRevenueEntry entry) => !entry.isSynced)
        .toList(growable: false);
  }

  Future<void> markSynced(String id) async {
    final WaybillRevenueEntry? entry = _box.get(id);
    if (entry == null) {
      return;
    }
    await _box.put(
        id, entry.copyWith(isSynced: true, updatedAt: DateTime.now()));
  }

  Future<double> calculateActualRevenue(
      String vehicleCode, DateTime date) async {
    final db_Provider dbProvider = Get.find<db_Provider>();
    final DateTime startDate = getdates(date);
    final DateTime endDate = getdates(date).add(const Duration(days: 1));
    final int startMs = startDate.millisecondsSinceEpoch;
    final int endMs = endDate.millisecondsSinceEpoch - 1;

    final String escapedVehicle = vehicleCode.replaceAll("'", "''");
    final String query =
        "SELECT SUM(${tmatatu.Trans.col_Amount}) AS total FROM ${tmatatu.Trans.tabletrans} "
        "WHERE ${tmatatu.Trans.col_Account_No} = '$escapedVehicle' "
        "AND ${tmatatu.Trans.col_Transaction_Date} BETWEEN $startMs AND $endMs";

    final List<Map<String, dynamic>> rows = await dbProvider.rawquery(query);
    if (rows.isEmpty) {
      return 0;
    }
    final dynamic value = rows.first['total'];
    if (value == null) {
      return 0;
    }
    if (value is int) {
      return value.toDouble();
    }
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return 0;
  }
}
