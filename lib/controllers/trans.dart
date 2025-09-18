import 'package:get/get.dart';
import 'package:t_matatu/models/Transaction.dart' as tmatatu;
import 'package:t_matatu/models/Utils/util.dart';

import '../providers/db.dart';

class TransController extends GetxController {
  RxList<tmatatu.Trans> daysTrans = <tmatatu.Trans>[].obs;

  Future<List<tmatatu.Trans>> gettransbydate(DateTime date) async {
    final results = await Get.find<db_Provider>().gettrans(
        tmatatu.Trans.columns,
        tmatatu.Trans.tabletrans,
        tmatatu.Trans.col_Transaction_Date,
        [getdates(date).microsecondsSinceEpoch]);
    Get.find<TransController>().daysTrans.value =
        results.map((map) => tmatatu.Trans.fromMap(map)).toList();

    return Get.find<TransController>().daysTrans;
  }
}
