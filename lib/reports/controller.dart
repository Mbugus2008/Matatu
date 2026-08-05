import 'package:get/get.dart';
import 'package:t_matatu/models/Transaction.dart' as tmatatu;
import 'package:t_matatu/models/summary/Tsummary.dart';
import 'package:t_matatu/models/summary/TsummaryDetails.dart';

import '../models/Header.dart';
import '../providers/db.dart';

class ReportController extends GetxController {
  Rx<DateTime?>? selectedDate = Rx<DateTime?>(null);
  RxBool searching = false.obs;
  RxList<Tsummary> tsummary = <Tsummary>[].obs;
  RxList<TsummaryDetails> tsummarydetails = <TsummaryDetails>[].obs;
  RxList<Header> daystrans = <Header>[].obs;
  RxList<Header> daystrans1 = <Header>[].obs;
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
    for (Header h in list) {
      final maps = await db_Provider().getrectrans(tmatatu.Trans.columns,
          tmatatu.Trans.tabletrans, h.Receipt_No.toString());
      // List<tmatatu.Trans> tr = [];
      if (maps.isNotEmpty) {
        h.transtions = maps.map((row) {
          return tmatatu.Trans.fromMap_t(row);
        }).toList();
      }
      // h.transtions = tr;
    }
    list.sort((a, b) => b.Receipt_No!.compareTo(a.Receipt_No.toString()));
    Get.find<ReportController>().daystrans.value = list;
    Get.find<ReportController>().daystrans1.value = list;
    // Get.find<ReportController>().daystrans[0].transtions?.forEach((element) {
    //   print(element.toString());
    // });
    return Future.value(null);
  }
}
