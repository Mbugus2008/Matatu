import 'package:get/get.dart';
import 'package:t_matatu/models/expences.dart';

import '../providers/db.dart';

class ExpenseController extends GetxController {
  RxList<Expenses> all = <Expenses>[].obs;

  Future<void> getall() async {
    Get.find<db_Provider>()
        .getalltrans(Expenses.columns, Expenses.table)
        .then((value) {
      if (value.isNotEmpty) {
        List<Expenses> tt = value.map((row) {
          return Expenses.fromMap(row);
        }).toList();

        Get.find<ExpenseController>().all.value = tt.toList();
      }
    });
  }

  @override
  void onInit() {
    super.onInit();
    getall();
  }

  @override
  void onReady() {
    super.onReady();
    // Put logic here that needs to run after the widget is rendered on the screen
    print('Controller Ready');
  }
}
