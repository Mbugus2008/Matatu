import 'package:get/get.dart';
import 'package:t_matatu/models/Transaction.dart' as tmatatu;
import 'package:t_matatu/models/summary/Tsummary.dart';
import 'package:t_matatu/models/summary/TsummaryDetails.dart';

import '../models/Header.dart';
import '../providers/db.dart';

class ReportController extends GetxController {
  Rx<DateTime>? selectedDate = DateTime.now().obs;
  RxBool searching = false.obs;
  RxList<Tsummary> tsummary = <Tsummary>[].obs;
  RxList<TsummaryDetails> tsummarydetails = <TsummaryDetails>[].obs;
  RxList<Header> daystrans = <Header>[].obs;
  RxList<Header> daystrans1 = <Header>[].obs;

  RxList<Header> daystranstoday = <Header>[].obs;
  RxList<Header> daystranstoday1 = <Header>[].obs;
  @override
  void onInit() {
    super.onInit();

    TsummaryDetails().getall();
    Tsummary().getall();

    //gettransbydate(DateTime.now());
  }

  Future<void> gettodaysdate() async {
    DateTime picked = DateTime.now();
    await Get.find<ReportController>().gettransbydate(picked);
  }

  Future<List<Header>?> gettransbydate(DateTime date) async {
    Get.find<ReportController>().daystrans.clear();
    List<Header> list = [];
    final maps = await Get.find<db_Provider>()
        .gettransbydate(Header.columns, Header.table, date);

    if (maps.isNotEmpty) {
      list = maps.map((row) {
        return Header.fromMap_d2(row);
      }).toList();
    }

    List<tmatatu.Trans> listtrans = [];
    final listmaps = await Get.find<db_Provider>()
        .gettransdate(tmatatu.Trans.columns, tmatatu.Trans.tabletrans, date);
    if (maps.isNotEmpty) {
      listtrans = listmaps.map((row) {
        return tmatatu.Trans.fromMap_t(row);
      }).toList();
    }
    // ✅ Group transactions by Receipt_No
    final Map<String, List<tmatatu.Trans>> grouped = {};
    for (final tr in listtrans) {
      if (tr.OTTN != null) {
        grouped.putIfAbsent(tr.OTTN!, () => []).add(tr);
      }
    }

// ✅ Attach to each header
    for (final h in list) {
      print("Sent Status: ${h.sent}");
      h.transtions = grouped[h.Receipt_No] ?? [];
    }

    list.sort((a, b) => b.Receipt_No!.compareTo(a.Receipt_No.toString()));

    Get.find<ReportController>().daystrans.value = list;
    Get.find<ReportController>().daystrans1.value = list;

    return Future.value(null);
  }

  Future<List<Header>?> gettransbydatetoday(DateTime date) async {
    Get.find<ReportController>().daystrans.clear();
    List<Header> list = [];
    final maps = await Get.find<db_Provider>()
        .gettransbydate(Header.columns, Header.table, date);

    if (maps.isNotEmpty) {
      list = maps.map((row) {
        return Header.fromMap_d2(row);
      }).toList();
    }

    List<tmatatu.Trans> listtrans = [];
    final listmaps = await Get.find<db_Provider>()
        .gettransdate(tmatatu.Trans.columns, tmatatu.Trans.tabletrans, date);
    if (maps.isNotEmpty) {
      listtrans = listmaps.map((row) {
        return tmatatu.Trans.fromMap_t(row);
      }).toList();
    }
    // ✅ Group transactions by Receipt_No
    final Map<String, List<tmatatu.Trans>> grouped = {};
    for (final tr in listtrans) {
      if (tr.OTTN != null) {
        grouped.putIfAbsent(tr.OTTN!, () => []).add(tr);
      }
    }

// ✅ Attach to each header
    for (final h in list) {
      print("Sent Status: ${h.sent}");
      h.transtions = grouped[h.Receipt_No] ?? [];
    }

    list.sort((a, b) => b.Receipt_No!.compareTo(a.Receipt_No.toString()));

    Get.find<ReportController>().daystranstoday.value = list;
    Get.find<ReportController>().daystranstoday1.value = list;

    return Future.value(null);
  }
}
