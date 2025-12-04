// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:t_matatu/controllers/main.dart';
import 'package:t_matatu/models/Header.dart';
import 'package:t_matatu/models/Transaction.dart' as tmatatu;
import 'package:t_matatu/models/mappings.dart';
import 'package:t_matatu/network/Apis.dart';
import 'package:t_matatu/network/errors.dart';
import 'package:t_matatu/network/request.dart';
import 'package:t_matatu/network/results/results.dart';
import 'package:t_matatu/providers/db.dart';
import 'package:t_matatu/providers/dbupdates.dart' as dbu;

import '../controllers/header.dart';
import '../init.dart';
import '../reports/controller.dart';
import 'Utils/util.dart';

class Reversal implements mapping, Tomaps, AbsDbUpdates {
  String? Key;
  String? No;
  String? Receipt_No;
  DateTime? Date;
  STatus? Status;
  String? Created_By;
  double? Total_Amount;
  int? Total_Trans;
  DateTime? Transction_Date;
  String? Agent;
  String? Reason_for_Reversal;
  String? Vehicle;
  String? Account;
  String? Name;
  bool? Sent;
  Reversal({
    this.Key,
    this.No,
    this.Receipt_No,
    this.Date,
    this.Status,
    this.Created_By,
    this.Total_Amount,
    this.Total_Trans,
    this.Transction_Date,
    this.Agent,
    this.Reason_for_Reversal,
    this.Vehicle,
    this.Account,
    this.Name,
    this.Sent,
  });
  @override
  String toString() {
    return '$Key $No $Receipt_No $Date $Status $Created_By $Total_Amount $Total_Trans $Transction_Date $Agent $Reason_for_Reversal $Vehicle $Account $Name $Sent';
  }

  @override
  Map<String, dynamic> toMap_fortable() {
    return <String, dynamic>{
      'Key': Key,
      'No': No,
      'Receipt_No': Receipt_No,
      'Date': Date?.millisecondsSinceEpoch,
      'Status': Status?.index,
      'Created_By': Created_By,
      'Total_Amount': Total_Amount,
      'Total_Trans': Total_Trans,
      'Transction_Date': Transction_Date?.millisecondsSinceEpoch,
      'Agent': Agent,
      'Reason_for_Reversal': Reason_for_Reversal,
      'Vehicle': Vehicle,
      'Account': Account,
      'Name': Name,
      'Sent': Sent,
    };
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'Key': Key,
      'No': No,
      'Receipt_No': Receipt_No,
      'Date': formattedDate.format(Date!),
      'Status': Status?.index,
      'Created_By': Created_By,
      'Total_Amount': Total_Amount,
      'Total_Trans': Total_Trans,
      'Transction_Date': formattedDate.format(Transction_Date!),
      'Agent': Agent,
      'Reason_for_Reversal': Reason_for_Reversal,
      'Vehicle': Vehicle,
      'Account': Account,
      'Name': Name,
      'Sent': Sent,
    };
  }

  factory Reversal.fromMap(Map<String, dynamic> map) {
    return Reversal(
      Key: map['Key'] != null ? map['Key'] as String : null,
      No: map['No'] != null ? map['No'] as String : null,
      Receipt_No:
          map['Receipt_No'] != null ? map['Receipt_No'] as String : null,
      Date: map['Date'] != null
          ? DateFormat("MM/dd/yyyy").parse((map['Date'] ?? 0))
          : null,
      Status:
          map['Status'] != null ? STatus.values[(map['Status']) as int] : null,
      Created_By:
          map['Created_By'] != null ? map['Created_By'] as String : null,
      Total_Amount:
          map['Total_Amount'] != null ? map['Total_Amount'] as double : null,
      Total_Trans:
          map['Total_Trans'] != null ? map['Total_Trans'] as int : null,
      Transction_Date: map['Transction_Date'] != null
          ? DateFormat("MM/dd/yyyy").parse((map['Transction_Date'] ?? 0))
          : null,
      Agent: map['Agent'] != null ? map['Agent'] as String : null,
      Reason_for_Reversal: map['Reason_for_Reversal'] != null
          ? map['Reason_for_Reversal'] as String
          : null,
      Vehicle: map['Vehicle'] != null ? map['Vehicle'] as String : null,
      Account: map['Account'] != null ? map['Account'] as String : null,
      Name: map['Name'] != null ? map['Name'] as String : null,
    );
  }
  factory Reversal.fromMap_d(Map<String, dynamic> map) {
    return Reversal(
      Key: map['Key'] != null ? map['Key'] as String : null,
      No: map['No'] != null ? map['No'] as String : null,
      Receipt_No:
          map['Receipt_No'] != null ? map['Receipt_No'] as String : null,
      Date: map['Date'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['Date'] ?? 0))
          : null,
      Status:
          map['Status'] != null ? STatus.values[(map['Status']) as int] : null,
      Created_By:
          map['Created_By'] != null ? map['Created_By'] as String : null,
      Total_Amount:
          map['Total_Amount'] != null ? map['Total_Amount'] as double : null,
      Total_Trans:
          map['Total_Trans'] != null ? map['Total_Trans'] as int : null,
      Transction_Date: map['Transction_Date'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['Transction_Date'] ?? 0))
          : null,
      Agent: map['Agent'] != null ? map['Agent'] as String : null,
      Reason_for_Reversal: map['Reason_for_Reversal'] != null
          ? map['Reason_for_Reversal'] as String
          : null,
      Vehicle: map['Vehicle'] != null ? map['Vehicle'] as String : null,
      Account: map['Account'] != null ? map['Account'] as String : null,
      Name: map['Name'] != null ? map['Name'] as String : null,
    );
  }
  String toJson() => json.encode(toMap());

  factory Reversal.fromJson(String source) =>
      Reversal.fromMap(json.decode(source) as Map<String, dynamic>);

  static const String table = 'Reversals';
  static const String col_Key = 'Key ';
  static const String col_No = 'No ';
  static const String col_Receipt_No = 'Receipt_No ';
  static const String col_Date = 'Date ';
  static const String col_Status = 'Status ';
  static const String col_Created_By = 'Created_By ';
  static const String col_Total_Amount = 'Total_Amount ';
  static const String col_Total_Trans = 'Total_Trans ';
  static const String col_Transction_Date = 'Transction_Date ';
  static const String col_Agent = 'Agent ';
  static const String col_Reason_for_Reversal = 'Reason_for_Reversal ';
  static const String col_Vehicle = 'Vehicle ';
  static const String col_Account = 'Account ';
  static const String col_Name = 'Name ';
  static const String col_Sent = 'Sent ';

  static const List<String> columns = [
    col_Key,
    col_No,
    col_Receipt_No,
    col_Date,
    col_Status,
    col_Created_By,
    col_Total_Amount,
    col_Total_Trans,
    col_Transction_Date,
    col_Agent,
    col_Reason_for_Reversal,
    col_Vehicle,
    col_Account,
    col_Name,
    col_Sent,
  ];

  static const String createtable = '''create table IF NOT EXISTS $table ( 
    $col_Key text ,
    $col_No text ,
    $col_Receipt_No text Not Null  ,
    $col_Date int,
    $col_Status int,
    $col_Created_By text Not Null,
    $col_Total_Amount float,
    $col_Total_Trans int,
    $col_Transction_Date int,
    $col_Agent text,
    $col_Reason_for_Reversal text,
    $col_Vehicle text,
    $col_Account text,
    $col_Name text,
    $col_Sent bit,
     PRIMARY KEY ($col_Receipt_No,  $col_Created_By)
 )
''';
  @override
  List<dbu.DbUpdate>? updates() {
    return dbu.getDbUpdatesForTable(table);
  }

  @override
  fromMap_table(Map<String, dynamic> map) {
    return Reversal.fromMap(map);
  }

  Future<void> downloadreversals() async {
    try {
      var request =
          Request(Agent: Get.find<MainController>().agent.value.Agent_Code);

      ApiClient().postdata("GetReversals", request.toJson()).then((r) async {
        if (r.statusCode == 200) {
          Results<Reversal> results =
              Results<Reversal>.fromJson(r.body, Reversal.fromMap);
          if (results.Code == 0) {
            if (results.Contents != null) {
              List<Reversal> reversals = results.Contents as List<Reversal>;

              for (var reversal in reversals) {
                if (reversal.Status == STatus.Approved) {
                  await processReversal(reversal);
                }
              }
              ;
              Get.find<db_Provider>().batchinsert(Reversal.table, reversals);
              ReversalController().updatereversals(reversals);
              Reversal().uploadreversal();
            }
          }
        }
      });
    } on Exception catch (e) {
      Errors().report(e);
    }
  }

  Future<void> processReversal(Reversal reversal) async {
    print('Approved');
    var app = await Get.find<db_Provider>().getdata(
        Header.table,
        Header.columns,
        '${Header.col_Receipt_No}=?',
        [reversal.Receipt_No.toString()]);

    if (app.isNotEmpty) {
      Header h = Header.fromMap_d2(app.first);
      Header h2 = h.copyWith();

      var app2 = await Get.find<db_Provider>().getdata(
          tmatatu.Trans.tabletrans,
          tmatatu.Trans.columns,
          '${tmatatu.Trans.col_OTTN}=?',
          [h.Receipt_No.toString()]);

      List<tmatatu.Trans> trans = app2.map((row) {
        return tmatatu.Trans.fromMap_d(row);
      }).toList();

      List<tmatatu.Trans> trans2 = [];
      for (var tt in trans) {
        tmatatu.Trans t = tt.copyWith();
        t.OTTN = '${t.OTTN}R';
        t.Document_No = '${t.Document_No}R';
        t.Amount = t.Amount! * -1;
        await Get.find<db_Provider>().insert(tmatatu.Trans.tabletrans, t);
        trans2.add(t);
      }

      h.transtions = trans;
      h.Reversal = true;
      h.Reversed = true;
      h2.Reversed = true;
      h2.Receipt_No = '${h2.Receipt_No}R';
      h2.Total_Amount = h2.Total_Amount! * -1;
      h2.transtions = trans2;
      await Get.find<db_Provider>().insert(Header.table, h2);
      Get.find<HeaderController>().trans.add(h2);
      Get.find<ReportController>().daystrans.add(h2);
       upload();

      reversal.Status = STatus.Released;
      reversal.Sent = false;
    }
  }

  Future<List<Reversal>?> getreversals() async {
    Get.find<ReversalController>().reversals.clear();
    Get.find<db_Provider>()
        .getalltrans(Reversal.columns, Reversal.table)
        .then((value) {
      if (value.isNotEmpty) {
        List<Reversal> tt = value.map((row) {
          return Reversal.fromMap_d(row);
        }).toList();
        ReversalController().updatereversals(tt);
      }
    });
    return Future.value(null);
  }

  Future<void> uploadreversal() async {
    final app = await Get.find<db_Provider>().getdata(
        Reversal.table,
        Reversal.columns,
        '${Reversal.col_Sent} IS NULL OR ${Reversal.col_Sent}=?',
        [false]);

    List<Reversal> up = app.map((row) {
      return Reversal.fromMap_d(row);
    }).toList();

    // print(up.length);
    // up.forEach((r) {
    //   print(r);
    // });

    for (var element in up) {
      try {
        await ApiClient()
            .postdata("Reversals", element.toJson())
            .then((r) async {
          if (r.statusCode == 200) {
            Results2<Reversal> results =
                Results2<Reversal>.fromJson(r.body, Reversal.fromMap);
            if (results.Code == 0) {
              if (results.Contents != null) {
                final h = results.Contents;
                if (h?.Key != null) {
                  h!.Sent = true;
                  Get.find<db_Provider>().insert(Reversal.table, h);
                }
              }
            }
          }
        });
      } catch (e) {
        e.printError();
      }
    }
    getreversals();
  }
}

class ReversalController extends GetxController {
  RxList<Reversal> reversals = <Reversal>[].obs;

  Future<void> refreshData() async {
    // Simulate fetching data from an API or database
    Reversal().downloadreversals();
  }

  void updatereversals(List<Reversal> reversal) {
    Get.find<ReversalController>().reversals.value = reversal.toList()
      ..sort((a, b) => b.Receipt_No!.compareTo(a.Receipt_No as String));
  }
}

enum STatus {
  /// <remarks/>
  Open,

  /// <remarks/>
  Released,

  /// <remarks/>
  Pending_Approval,

  /// <remarks/>
  Approved,

  /// <remarks/>
  Rejected,
}

extension StatusDescription on STatus {
  String get description {
    switch (this) {
      case STatus.Open:
        return 'Open';
      case STatus.Released:
        return 'Released';
      case STatus.Pending_Approval:
        return 'Pending';
      case STatus.Approved:
        return 'Approved';
      case STatus.Rejected:
        return 'Rejected';
      default:
        return 'Unknown status';
    }
  }
}


