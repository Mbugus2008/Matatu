import 'package:get/get.dart';
import 'package:t_matatu/controllers/header.dart';
import 'package:t_matatu/models/Tamounts.dart';
import 'package:t_matatu/models/vehicles/vehicle.dart';
import 'package:t_matatu/providers/db.dart';

import '../models/trantypes.dart';

class TransTypeController extends GetxController {
  RxList<TranTypes> alltrantypes = <TranTypes>[].obs;
  RxList<TranTypes> vehicleTrantypes = <TranTypes>[].obs;
  RxBool loading = false.obs;
  RxList<Tamounts> alltranamounts = <Tamounts>[].obs;
  Rx<TranTypes> tType = TranTypes(Code: " ").obs;
  RxBool test = false.obs;
  @override
  Future<void> onInit() async {
    super.onInit();
  }

  Future<void> start() async {
    await initialize();
  }

  void distribute(double amount) {
    final controller = Get.find<TransTypeController>();
    final types = controller.vehicleTrantypes
        .where((p0) => p0.Name != null)
        .toList();

    // Start from a clean slate.
    for (final element in types) {
      element.Amountedited = 0;
      element.Checked = false;
      element.eAmount.text = '0.00';
    }

    // Fill in the same order the screen shows: biggest expected first.
    // "== balance" must allocate too, otherwise the remainder rolls past a
    // type that matches exactly.
    final ordered = [...types]..sort(compareByExpectedDesc);
    var left = amount;
    for (final element in ordered) {
      if (left <= 0) break;
      final bal = (element.VehicleAmount ?? 0) - (element.Amounttoday ?? 0);
      if (bal <= 0) continue;

      final allocate = left >= bal ? bal : left;
      element.Amountedited = allocate;
      element.eAmount.text = allocate.toStringAsFixed(2);
      element.Checked = true;
      left -= allocate;
    }

    // Whatever is left over goes to OFFLOAD — add to any amount it already got
    // from the loop, and only to the first matching row.
    if (left > 0) {
      final offload =
          types.firstWhereOrNull((p0) => p0.Code == 'OFFLOAD');
      if (offload != null) {
        offload.Amountedited = (offload.Amountedited ?? 0) + left;
        offload.eAmount.text = offload.Amountedited!.toStringAsFixed(2);
        offload.Checked = true;
      }
    }

    update();
  }

  double? get_selected() {
    final tp = Get.find<TransTypeController>()
        .vehicleTrantypes
        .where((p0) => p0.Checked == true && p0.Code != " ")
        .toList();
    if (tp.isEmpty) return 0;
    // Guarded parse: legacy rows can hold empty/garbage amounts.
    return tp.fold<double>(
        0.0, (sum, item) => sum + (item.Amountedited ?? 0));
  }

  Future<void> initialize() async {
    Get.find<db_Provider>()
        .getalltrans(TranTypes.columns, TranTypes.table)
        .then((value) {
      if (value.isNotEmpty) {
        var tt = value.map((row) {
          return TranTypes.fromMap_fortable(row);
        });
        Get.find<TransTypeController>().alltrantypes.clear();

        Get.find<TransTypeController>().alltrantypes.value = tt.toList();

        Get.find<TransTypeController>()
            .alltrantypes
            .sort((a, b) => a.Order!.compareTo(b.Order as num));
      }
    });
    Get.find<db_Provider>()
        .getalltrans(Tamounts.columns, Tamounts.table)
        .then((map) {
      if (map.isNotEmpty) {
        List<Tamounts> ttt = map.map((row) {
          return Tamounts.fromMap(row);
        }).toList();
        Get.find<TransTypeController>().alltranamounts.clear();
        Get.find<TransTypeController>().alltranamounts.value = ttt.toList();
      }
    });
  }

  void toggle(int item) {
    if (Get.find<TransTypeController>().vehicleTrantypes[item].Checked ==
        true) {
      Get.find<HeaderController>().currTrans.removeWhere((element) =>
          element.Type ==
          Get.find<TransTypeController>().vehicleTrantypes[item].Code);
    }
    Get.find<TransTypeController>().vehicleTrantypes[item].Checked =
        Get.find<TransTypeController>().vehicleTrantypes[item].Checked == true
            ? false
            : true;

    update();
  }

  /// Toggles one specific type by identity. Safe for lists that are filtered or
  /// re-ordered for display, unlike [toggle] which takes an index into
  /// [vehicleTrantypes] (crew savings produce two rows with the same code, so an
  /// index/code lookup would toggle the wrong one).
  void toggleType(TranTypes type) {
    final item = Get.find<TransTypeController>()
        .vehicleTrantypes
        .firstWhereOrNull((t) => identical(t, type));
    if (item == null) return;

    if (item.Checked == true) {
      Get.find<HeaderController>()
          .currTrans
          .removeWhere((element) => element.Type == item.Code);
    }
    item.Checked = item.Checked != true;
    update();
  }

  /// Order used by the distribute screen and by the allocation itself:
  /// biggest expected amount first, ties keep the configured order.
  static int compareByExpectedDesc(TranTypes a, TranTypes b) {
    final cmp = (b.VehicleAmount ?? 0).compareTo(a.VehicleAmount ?? 0);
    if (cmp != 0) return cmp;
    return (a.Order ?? 0).compareTo(b.Order ?? 0);
  }

  // get alltrantypes => _alltrantypes;
  Future<List<TranTypes>> vehicleTypes(vehicle_type? vehicleType) async {
    List<TranTypes> types = [...Get.find<TransTypeController>().alltrantypes];

    Get.find<TransTypeController>().vehicleTrantypes.clear();
    List<TranTypes> typess = [];
    TranTypes? type;

    for (var element in types) {
      final tamount = Get.find<TransTypeController>()
          .alltranamounts
          .firstWhereOrNull((el) =>
              el.Vehicle_Type == vehicleType && el.Code == element.Code);
      element.VehicleAmount = tamount == null ? 0 : tamount.Amount;
      element.Amountedited = 0;
      element.Checked = false;
      element.Account = Get.find<HeaderController>().currHeader.value.Account;
      if (element.Code == "SAVINGSCREW") {
        type = element.copyWith();
        if (Get.find<HeaderController>().currHeader.value.Crew?.isEmpty ==
            false) {
          element.Name =
              '${element.Name2}(${Get.find<HeaderController>().currHeader.value.Crew})';
          element.Account = Get.find<HeaderController>().currHeader.value.Crew;
          typess.add(element);
        }
      } else {
        typess.add(element);
      }

      if (element.Code == "SAVINGSCREW") {
        if (Get.find<HeaderController>().currHeader.value.Crew2?.isEmpty ==
            false) {
          type!.Name =
              '${type.Name2}(${Get.find<HeaderController>().currHeader.value.Crew2})';
          type.Account = Get.find<HeaderController>().currHeader.value.Crew2;
          typess.add(type);
        }
      }
    }

    Get.find<TransTypeController>().vehicleTrantypes.value = typess;
    return typess;
  }
}
