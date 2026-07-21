import 'package:get/get.dart';
import 'package:t_matatu/models/expenses/expenses.dart';

import '../../providers/db.dart';

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

  Future<void> syncFromApi() async {
    await Expenses().download();
    await getall();
  }

  @override
  void onInit() {
    super.onInit();
    getall();
    // syncFromApi() is called later after config is set
  }

  @override
  void onReady() {
    super.onReady();
    print('Controller Ready');
  }
}
