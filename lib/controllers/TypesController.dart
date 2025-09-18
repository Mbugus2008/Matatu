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
    Get.find<TransTypeController>()
        .vehicleTrantypes
        .where((p0) => p0.Name != null)
        .forEach((element) {
      element.Amountedited = 0;
      element.Checked = false;
    });

    Get.find<TransTypeController>()
        .vehicleTrantypes
        .where((p0) => p0.Name != null)
        .forEach((element) {
      double bal = element.VehicleAmount! - element.Amounttoday!;
      if ((bal > 0) && (amount > 0)) {
        if (amount > bal) {
          element.Amountedited = bal;
          element.eAmount.text = '${element.Amountedited}';
          element.Checked = true;
        }
        if (amount < bal) {
          element.Amountedited = amount;
          element.eAmount.text = '${element.Amountedited}';
          element.Checked = true;
        }
      }
      amount -= element.Amountedited!;
      if (amount <= 0) return;
    });
    if (amount > 0) {
      Get.find<TransTypeController>()
          .vehicleTrantypes
          .where((p0) => p0.Code == "OFFLOAD")
          .forEach((element) {
        element.Amountedited = amount;
        element.eAmount.text = '${element.Amountedited}';
        element.Checked = true;
      });
    }
    update();
  }

  double? get_selected() {
    double dd = 0;
    List<TranTypes> tp = Get.find<TransTypeController>()
        .vehicleTrantypes
        .where((p0) => p0.Checked == true && p0.Code != " ")
        .toList();
    if (tp.isNotEmpty) {
      dd = tp.fold<double>(
          0.0,
          (double currentSum, TranTypes item) =>
              currentSum +
              num.tryParse(item.Amountedited == null
                  ? ""
                  : item.Amountedited.toString())!);
    }
    // update();
    return dd;
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

        print(tt.length);
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
