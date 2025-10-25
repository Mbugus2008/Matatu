import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:t_matatu/controllers/SettingsController.dart';
import 'package:t_matatu/controllers/TypesController.dart';
import 'package:t_matatu/controllers/agent.dart';
import 'package:t_matatu/controllers/main.dart';
import 'package:t_matatu/init.dart';
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
    ReportController().gettransbydatetoday(DateTime.now());

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
    //   final app = await Get.find<db_Provider>().getdata(
    //       Reversal.table, Reversal.columns, '${Reversal.col_Receipt_No}=?', [header.Receipt_No.toString()]);
    //   if (app.length>0)

    // { Get.snackbar(
    //   'Reversal',
    //   'Reversal Request Exist',
    //   backgroundColor: Colors.red, // Customize the background color
    //   duration: const Duration(
    //       seconds: 3), // Set the duration the snackbar is displayed
    //   snackPosition:
    //   SnackPosition.BOTTOM, // Set the position of the snackbar
    // );}

    //   Reversal reversal = Reversal();
    //   reversal.Account = header.Account;
    //   reversal.Receipt_No = header.Receipt_No;
    //   reversal.Agent = header.Agent;
    //   reversal.Date = DateTime.now();
    //   reversal.Transction_Date = header.Date;
    //   reversal.Created_By = Get.find<MainController>().agent.value.Agent_Code;
    //   reversal.Total_Amount = header.Total_Amount;
    //   reversal.Total_Trans = header.Trans;
    //   reversal.Vehicle = header.Vehicle;
    //   reversal.Sent = false;
    //   reversal.Status = STatus.Open;

    //   await Get.find<db_Provider>().insert(Reversal.table, reversal);
    //   Reversal().uploadreversal();

    final rev = header.copyWith(
      Key: header.Key,
      Receipt_No: header.Receipt_No,
      Date: header.Date,
      Account: header.Account,
      Vehicle: header.Vehicle,
      Posted: header.Posted,
      Reversal: header.Reversal,
      Reversed: header.Reversed,
      sent: header.sent,
      Trans: header.Trans,
      Total_Amount: header.Total_Amount,
      Agent: header.Agent,
      transtions: header.transtions,
    );
    rev.Reversed = true;
    rev.Reversal = true;
    rev.Receipt_No = '${rev.Receipt_No}R';
    rev.Total_Amount = rev.Total_Amount! * -1;

    header.Reversed = true;
    await db_Provider().updatedata(
      Header.table,
      {Header.col_Reversed: true},
      '${Header.col_Receipt_No} = ?',
      [header.Receipt_No.toString()],
    );
    // await Get.find<db_Provider>().database.update(
    //       Header.table,
    //       {Header.col_Reversed: true},
    //       where: '${Header.col_Receipt_No} = ?',
    //       whereArgs: [header.Receipt_No],
    //     );
    await Get.find<db_Provider>().insert(Header.table, rev);

    if (rev.transtions != null) {
      for (var element in rev.transtions!.toList()) {
        tmatatu.Trans t = element.copyWith(
          Key: element.Key,
          Document_No: element.Document_No,
          Transaction_Date: element.Transaction_Date,
          Account_No: element.Account_No,
          Description: element.Description,
          Amount: element.Amount,
          Posted: element.Posted,
          Transaction_Time: element.Transaction_Time,
          Messages: element.Messages,
          OTTN: element.OTTN,
          Transaction_Location: element.Transaction_Location,
          Transaction_By: element.Transaction_By,
          Agent_Code: element.Agent_Code,
          Loan_No: element.Loan_No,
          Account_Name: element.Account_Name,
          Telephone: element.Telephone,
          Id_No: element.Id_No,
          Constituency: element.Constituency,
          Ward: element.Ward,
          Type: element.Type,
          sent: element.sent,
          Creation_time: element.Creation_time,
        );
        t.OTTN = '${t.OTTN}R';
        t.Document_No = '${t.Document_No}R';
        t.Amount = t.Amount! * -1;
        await Get.find<db_Provider>().insert(tmatatu.Trans.tabletrans, t);
      }
    }
    // Get.find<HeaderController>().filteredTrans.add(rev);
    Get.find<HeaderController>().trans.add(rev);
    Get.find<ReportController>().daystrans.add(rev);
    upload();
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
