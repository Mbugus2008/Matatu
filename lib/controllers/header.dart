import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:t_matatu/controllers/SettingsController.dart';
import 'package:t_matatu/controllers/TypesController.dart';
import 'package:t_matatu/controllers/main.dart';
import 'package:t_matatu/models/Header.dart';
import 'package:t_matatu/models/Reversal.dart';
import 'package:t_matatu/models/Transaction.dart' as tmatatu;
import 'package:t_matatu/models/agents.dart';
import 'package:t_matatu/reports/controller.dart';

import '../models/Utils/util.dart';
import '../models/Utils/veh_mem.dart';
import '../models/member.dart';
import '../models/summary/Tsummary.dart';
import '../models/summary/TsummaryDetails.dart';
import '../models/vehicles/Vehicle_crew.dart';
import '../models/vehicles/vehicle.dart';
import '../providers/db.dart';

class HeaderController extends GetxController {
  RxList<Header> trans = <Header>[].obs;

  RxList<Header> filteredTrans = <Header>[].obs;

  RxList<Vehicle_Crew> currentcrew = <Vehicle_Crew>[].obs;
  RxList<InputSuggetions> suggestions = <InputSuggetions>[].obs;

  Rx<Header> currHeader = Header().obs;
  Rx<Vehicles> currvehicle = Vehicles().obs;
  RxList<tmatatu.Trans> currTrans = <tmatatu.Trans>[].obs;
  Rx<tmatatu.Trans> curTran = tmatatu.Trans().obs;

  Rx<TextEditingController> textEditingController = TextEditingController().obs;
  Rx<TextEditingController> amountEditingController =
      TextEditingController().obs;

  String displayStringForOption(InputSuggetions option) =>
      option.Vehicle.toString();
  final filteredSuggestions = <InputSuggetions>[].obs;

  void createheader() {
    Agent().getagents();
    Get.find<HeaderController>().currHeader.value = Header();
    Get.find<HeaderController>().currHeader.value.Date =
        getdates(Get.find<SettingsController>().settings.value!.WorkingDate);
    Get.find<HeaderController>().currHeader.value.Receipt_No =
        DateTime.now().microsecondsSinceEpoch.toString();
    Get.find<HeaderController>().currHeader.value.Agent =
        Get.find<MainController>().agent.value.Agent_Code;
    Get.find<HeaderController>().currHeader.value.sent = false;
    Get.find<HeaderController>().currHeader.value.transtions = [];

    TsummaryDetails().getall();
    Tsummary().getall();
    ReportController().gettransbydate(DateTime.now());

    // DateTime(year, month, day);
  }

  void createlines() {
    final selected = Get.find<TransTypeController>().vehicleTrantypes.where(
        (p0) => p0.Checked == true && p0.Code != " " && p0.Amountedited! > 0);
    for (var element in selected) {
      Get.find<HeaderController>().currHeader.value.Customer_Posting_Group =
          element.Customer_Posting_Group;
      Get.find<HeaderController>().curTran = tmatatu.Trans().obs;
      Get.find<HeaderController>().curTran.value.Document_No =
          DateTime.now().microsecondsSinceEpoch.toString();
      Get.find<HeaderController>().curTran.value.OTTN =
          Get.find<HeaderController>().currHeader.value.Receipt_No;
      Get.find<HeaderController>().curTran.value.Account_No =
          Get.find<HeaderController>().currHeader.value.Account;
      if ((element.Account != "") && (element.Account != null)) {
        Get.find<HeaderController>().curTran.value.Account_No = element.Account;
      }
      Get.find<HeaderController>().curTran.value.Loan_No =
          Get.find<HeaderController>().currHeader.value.Vehicle;
      Get.find<HeaderController>().curTran.value.Transaction_Date =
          Get.find<HeaderController>().currHeader.value.Date;
      Get.find<HeaderController>().curTran.value.Type = element.Code;
      Get.find<HeaderController>().curTran.value.Amount = element.Amountedited;
      if (Get.find<HeaderController>().curTran.value.Type == "EXPENSES") {
        Get.find<HeaderController>().curTran.value.Amount =
            element.Amountedited! * -1;
      }
      Get.find<HeaderController>().curTran.value.Description = element.Name;
      Get.find<HeaderController>().curTran.value.Transaction_Time =
          DateTime.now();
      Get.find<HeaderController>().curTran.value.Agent_Code =
          Get.find<HeaderController>().currHeader.value.Agent;
      Get.find<HeaderController>().curTran.value.sent = false;
      final t = Get.find<HeaderController>().currTrans.where((p0) =>
          p0.OTTN == Get.find<HeaderController>().currHeader.value.Receipt_No &&
          p0.Type == element.Code &&
          p0.Description == element.Name);

      if (t.isEmpty) {
        Get.find<HeaderController>()
            .currTrans
            .add(Get.find<HeaderController>().curTran.value);
      }

      Get.find<HeaderController>()
          .currHeader
          .value
          .transtions!
          .add(Get.find<HeaderController>().curTran.value);

      // if ((element.Code == "SAVINGSCREW") &&
      //     (Get.find<HeaderController>().currHeader.value.Crew2 != null ||
      //         Get.find<HeaderController>().currHeader.value.Crew2 != "")) {
      //   tmatatu.Trans conductor =
      //       Get.find<HeaderController>().curTran.value.copyWith();
      //   conductor.Document_No = '${conductor.Document_No}C';
      //   conductor.Account_No =
      //       Get.find<HeaderController>().currHeader.value.Crew2;
      //   Get.find<HeaderController>().currTrans.add(conductor);
      //   Get.find<HeaderController>()
      //       .currHeader
      //       .value
      //       .transtions!
      //       .add(conductor);
      // }
    }
  }

  Future<List<Header>?> gettodaystrans() async {
    List<Header> list = [];
    Get.find<db_Provider>()
        .gettodaytrans(Header.columns, Header.table)
        .then((value) {
      if (value.isNotEmpty) {
        list = value.map((row) {
          return Header.fromMap_d2(row);
        }).toList();

        for (var element in list) {
          Get.find<db_Provider>()
              .getrectrans(tmatatu.Trans.columns, tmatatu.Trans.tabletrans,
                  element.Receipt_No.toString())
              .then((value) {
            element.transtions = value.map((row) {
              return tmatatu.Trans.fromMap_t(row);
            }).toList();
          });
        }
        list.sort((a, b) => b.Receipt_No!.compareTo(a.Receipt_No.toString()));
        Get.find<HeaderController>().trans.value = list;
        Get.find<HeaderController>().filteredTrans.value = list;
      }
    });

    // for (Header h in Get.find<HeaderController>().trans) {
    //   final maps = await Get.find<MainController>().db.getrectrans(
    //       tmatatu.Trans.columns,
    //       tmatatu.Trans.tabletrans,
    //       h.Receipt_No.toString());
    //   // List<tmatatu.Trans> tr = [];
    //   if (maps.isNotEmpty) {
    //     h.transtions = maps.map((row) {
    //       return tmatatu.Trans.fromMap_t(row);
    //     }).toList();
    //   }

    //   // h.transtions = tr;
    // }
    // Get.find<HeaderController>().filteredTrans.value =
    //     Get.find<HeaderController>().trans;
    return Future.value(null);
  }

  void removetrans(tmatatu.Trans index) {
    Get.find<HeaderController>().currTrans.remove(index);
    Get.find<HeaderController>().currHeader.value.transtions!.remove(index);
    Get.find<TransTypeController>()
        .vehicleTrantypes
        .firstWhereOrNull((element) => element.Code == index.Type)!
        .Checked = false;
  }

  Future<void> getvehcrew(String vehicle) async {
    final maps = await Get.find<db_Provider>()
        .getvehiclecrews(Vehicle_Crew.columns, Vehicle_Crew.table, vehicle);

    if (maps.isNotEmpty) {
      List<Vehicle_Crew> tt = maps.map((row) {
        return Vehicle_Crew.fromMap_db(row);
      }).toList();

      Get.find<HeaderController>().currentcrew.value = tt.toList();
    }

    return Future.value(null);
  }

  void cleartrans() {
    Get.find<HeaderController>().curTran = tmatatu.Trans().obs;
    Get.find<MainController>().vehsummary.clear();
    Get.find<HeaderController>().currTrans.clear();
    Get.find<HeaderController>().currentcrew.clear();
  }

  Future<void> reverse(Header header) async {
    final db = Get.find<db_Provider>();
    final receiptNo = header.Receipt_No?.toString() ?? '';
    final createdBy = Get.find<MainController>().agent.value.Agent_Code ?? '';

    if (receiptNo.isEmpty || createdBy.isEmpty) {
      Get.snackbar(
        'Reversal',
        'Unable to create reversal request',
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (header.Reversed == true || header.Reversal == true) {
      Get.snackbar(
        'Reversal',
        'Reversal request already exists',
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final existing = await db.getdata(
      Reversal.table,
      Reversal.columns,
      '${Reversal.col_Receipt_No}=?',
      [receiptNo],
    );

    if (existing.isNotEmpty) {
      header.Reversal = true;
      await db.updatedata(
        Header.table,
        {Header.col_Reversal: true},
        '${Header.col_Receipt_No} = ?',
        [receiptNo],
      );
      Get.find<ReportController>().daystrans.refresh();
      Get.find<HeaderController>().trans.refresh();
      Get.snackbar(
        'Reversal',
        'Reversal request already exists',
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final reversal = Reversal(
      Account: header.Account,
      Receipt_No: receiptNo,
      Agent: header.Agent,
      Date: DateTime.now(),
      Transction_Date: header.Date,
      Created_By: createdBy,
      Total_Amount: header.Total_Amount,
      Total_Trans: header.Trans ?? header.transtions?.length ?? 0,
      Vehicle: header.Vehicle,
      Sent: false,
      Status: STatus.Open,
    );

    await db.insert(Reversal.table, reversal);

    header.Reversal = true;
    await db.updatedata(
      Header.table,
      {Header.col_Reversal: true},
      '${Header.col_Receipt_No} = ?',
      [receiptNo],
    );
    Get.find<ReportController>().daystrans.refresh();
    Get.find<HeaderController>().trans.refresh();

    await Reversal().getreversals();
    await Reversal().uploadreversal();

    Get.snackbar(
      'Reversal',
      'Reversal request submitted',
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 3),
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> getsuggetions() async {
    suggestions.clear();
    final maps = await Get.find<db_Provider>()
        .getvehicles(Vehicles.columns, Vehicles.table);

    if (maps.isNotEmpty) {
      List<Vehicles> tt = maps.map((row) {
        return Vehicles.fromMap(row);
      }).toList();
      for (var element in tt) {
        if (element.Vehicle_Number != null) {
          suggestions.add(InputSuggetions(
              Vehicle: element.Vehicle_Number as String,
              Fleet: element.Fleet_No,
              Account: element.Code,
              Vehicle_Type: element.Vehicle_Type,
              type: SuggestionType.vehicle));
        }
      }
    }
    final mapss =
        await Get.find<db_Provider>().getmembers(Member.columns, Member.table);

    if (mapss.isNotEmpty) {
      List<Member> tt = mapss.map((row) {
        return Member.fromMap(row);
      }).toList();
      for (var element in tt) {
        if ((element.No != null) &&
            (element.Customer_Posting_Group == "CREW")) {
          Get.find<HeaderController>().suggestions.add(InputSuggetions(
              Vehicle: element.No as String,
              Fleet: element.Name,
              Account: element.No,
              type: element.Customer_Posting_Group == 'MEMBER'
                  ? SuggestionType.Member
                  : SuggestionType.Crew));
        }
      }
    }
    print('Found suggestions');
    return Future.value(null);
  }

  void clearAllTransactions() {
    currTrans.clear();
    currHeader.value = Header(); // Reset header
    amountEditingController.value.clear(); // Clear amount field
    update();
  }
}
