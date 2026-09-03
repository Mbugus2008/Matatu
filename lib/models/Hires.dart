// ignore_for_file: camel_case_types

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:t_matatu/models/Utils/util.dart';
import 'package:t_matatu/models/enums.dart';
import 'package:t_matatu/models/mappings.dart';
import 'package:t_matatu/network/Apis.dart';
import 'package:t_matatu/network/errors.dart';
import 'package:t_matatu/network/request.dart';
import 'package:t_matatu/network/results/results.dart';
import 'package:t_matatu/providers/db.dart';
import 'package:t_matatu/providers/logger.dart';

class HiresController extends GetxController {
  final hires = <Hires>[].obs;
  final selectedHire = Hires().obs;
  final isLoading = false.obs;
  final isAdding = false.obs;
  final isEditing = false.obs;
}

@JsonSerializable()
class Hires implements mapping, Tomaps, AbsDbUpdates {
  String? Key;
  String? Vehicle_No;
  DateTime? Start_Date;
  DateTime? Start_Time;
  DateTime? Return_Date;
  DateTime? Return_Time;
  double? Amount;
  client? Client;
  hire_Type? Hire_Type;
  vat_Type? Vat_Type;
  payment_Methods? Payment_Methods;
  int? Entry;
  String? Created_by;
  String? Code;
  String? Fleet_No;
  String? Destination;
  String? Client_Name;
  String? Incharge;
  String? Department;
  String? Driver;
  Hires({
    this.Key,
    this.Vehicle_No,
    this.Start_Date,
    this.Start_Time,
    this.Return_Date,
    this.Return_Time,
    this.Amount,
    this.Client,
    this.Hire_Type,
    this.Vat_Type,
    this.Payment_Methods,
    this.Entry,
    this.Created_by,
    this.Code,
    this.Fleet_No,
    this.Destination,
    this.Client_Name,
    this.Incharge,
    this.Department,
    this.Driver,
  });
  @override
  String toString() {
    return ' $Code Vehicle_No: $Vehicle_No  Start_Date: $Start_Date Start_Time: $Start_Time Return_Date: $Return_Date Return_Time: $Return_Time Amount: $Amount Client: $Client Hire_Type: $Hire_Type Vat_Type: $Vat_Type Payment_Methods: $Payment_Methods Entry: $Entry Created_by: $Created_by Fleet_No: $Fleet_No Destination: $Destination Client_Name: $Client_Name Incharge: $Incharge Department: $Department Driver: $Driver';
  }

  factory Hires.fromJson(String source) =>
      Hires.fromMap(json.decode(source) as Map<String, dynamic>);

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'Key': Key,
      'Vehicle_No': Vehicle_No,
      'Start_Date': formattedDate.format(Start_Date!),
      'Start_Time': formattedDateTime.format(Start_Time!),
      'Return_Date': formattedDate.format(Return_Date!),
      'Return_Time': formattedDateTime.format(Return_Time!),
      'Amount': Amount,
      'Client': Client?.index,
      'Hire_Type': Hire_Type?.index,
      'Vat_Type': Vat_Type?.index,
      'Payment_Methods': Payment_Methods?.index,
      // Entry must never be null in JSON - BC's WCF model is a non-nullable
      // int and ASP.NET rejects null (HTTP 400). 0 + EntrySpecified=false
      // means NAV assigns/keeps the real entry number.
      'Entry': Entry ?? 0,
      'Created_by': Created_by,
      'Code': Code,
      'Fleet_No': Fleet_No,
      'Destination': Destination,
      'Client_Name': Client_Name,
      'Incharge': Incharge,
      'Department': Department,
      'Driver': Driver,
    };
  }

  String toJson() => json.encode(toMap());

  factory Hires.fromMap_fortable(Map<String, dynamic> map) {
    final dateFormat = DateFormat('MM/dd/yyyy HH:mm:ss');
    final dateFormat2 = DateFormat('HH:mm:ss');
    DateTime? parsedDate, runbacktime;
    try {
      print("map['Start_Time']: ${map['Start_Time']}");
      parsedDate = dateFormat2.parse(map['Start_Time'] as String);
      runbacktime = dateFormat2.parse(map['Return_Time'] as String);
    } catch (e) {}
    return Hires(
      Key: map['Key'] != null ? map['Key'] as String : null,
      Vehicle_No:
          map['Vehicle_No'] != null ? map['Vehicle_No'] as String : null,
      Start_Date: map['Start_Date'] != null
          ? DateFormat("MM/dd/yyyy").parse((map['Start_Date'] ?? 0))
          : null,
      Start_Time: parsedDate,
      Return_Date: map['Return_Date'] != null
          ? DateFormat("MM/dd/yyyy").parse((map['Return_Date'] ?? 0))
          : null,
      Return_Time: runbacktime,
      Amount: map['Amount'] != null ? (map['Amount'] as num).toDouble() : null,
      Client:
          map['Client'] != null ? client.values[(map['Client'] as int)] : null,
      Hire_Type: map['Hire_Type'] != null
          ? hire_Type.values[(map['Hire_Type'] as int)]
          : null,
      Vat_Type: map['Vat_Type'] != null
          ? vat_Type.values[(map['Vat_Type'] as int)]
          : null,
      Payment_Methods: map['Payment_Methods'] != null
          ? payment_Methods.values[(map['Payment_Methods'] as int)]
          : null,
      Code: map['Code'] != null ? map['Code'] as String : null,
      Created_by:
          map['Created_by'] != null ? map['Created_by'] as String : null,
      Fleet_No: map['Fleet_No'] != null ? map['Fleet_No'] as String : null,
      Destination:
          map['Destination'] != null ? map['Destination'] as String : null,
      Client_Name:
          map['Client_Name'] != null ? map['Client_Name'] as String : null,
      Incharge: map['Incharge'] != null ? map['Incharge'] as String : null,
      Department:
          map['Department'] != null ? map['Department'] as String : null,
      Driver: map['Driver'] != null ? map['Driver'] as String : null,
    );
  }

  factory Hires.fromMap(Map<String, dynamic> map) {
    final dateFormat = DateFormat('MM/dd/yyyy HH:mm:ss');

    DateTime? parsedDate, runbacktime;
    try {
      parsedDate = dateFormat.parse(map['Start_Time'] as String);
      runbacktime = dateFormat.parse(map['Return_Time'] as String);
    } catch (e) {}
    return Hires(
      Key: map['Key'] != null ? map['Key'] as String : null,
      Vehicle_No:
          map['Vehicle_No'] != null ? map['Vehicle_No'] as String : null,
      Start_Date: map['Start_Date'] != null
          ? DateFormat("MM/dd/yyyy").parse((map['Start_Date'] ?? 0))
          : null,
      Start_Time: parsedDate,
      Return_Date: map['Return_Date'] != null
          ? DateFormat("MM/dd/yyyy").parse((map['Return_Date'] ?? 0))
          : null,
      Return_Time: runbacktime,
      Amount: map['Amount'] != null ? (map['Amount'] as num).toDouble() : null,
      Client:
          map['Client'] != null ? client.values[(map['Client'] as int)] : null,
      Hire_Type: map['Hire_Type'] != null
          ? hire_Type.values[(map['Hire_Type'] as int)]
          : null,
      Vat_Type: map['Vat_Type'] != null
          ? vat_Type.values[(map['Vat_Type'] as int)]
          : null,
      Payment_Methods: map['Payment_Methods'] != null
          ? payment_Methods.values[(map['Payment_Methods'] as int)]
          : null,
      Entry: map['Entry'] != null ? map['Entry'] as int : null,
      Created_by:
          map['Created_by'] != null ? map['Created_by'] as String : null,
      Code: map['Code'] != null ? map['Code'] as String : null,
      Fleet_No: map['Fleet_No'] != null ? map['Fleet_No'] as String : null,
      Destination:
          map['Destination'] != null ? map['Destination'] as String : null,
      Client_Name:
          map['Client_Name'] != null ? map['Client_Name'] as String : null,
      Incharge: map['Incharge'] != null ? map['Incharge'] as String : null,
      Department:
          map['Department'] != null ? map['Department'] as String : null,
      Driver: map['Driver'] != null ? map['Driver'] as String : null,
    );
  }

  static const String table = 'Hires';
  static const String col_Key = 'Key';
  static const String col_Vehicle_No = 'Vehicle_No';
  static const String col_Code = 'Code';
  static const String col_Start_Date = 'Start_Date';
  static const String col_Start_Time = 'Start_Time';
  static const String col_Return_Date = 'Return_Date';
  static const String col_Return_Time = 'Return_Time';
  static const String col_Amount = 'Amount';
  static const String col_Client = 'Client';
  static const String col_Hire_Type = 'Hire_Type';
  static const String col_Vat_Type = 'Vat_Type';
  static const String col_Payment_Methods = 'Payment_Methods';
  static const String col_Entry = 'Entry';
  static const String col_Created_by = 'Created_by';
  static const String col_Fleet_No = 'Fleet_No';
  static const String col_Destination = 'Destination';
  static const String col_Client_Name = 'Client_Name';
  static const String col_Incharge = 'Incharge';
  static const String col_Department = 'Department';
  static const String col_Driver = 'Driver';
  static const List<String> columns = [
    col_Key,
    col_Vehicle_No,
    col_Start_Date,
    col_Start_Time,
    col_Return_Date,
    col_Return_Time,
    col_Amount,
    col_Client,
    col_Hire_Type,
    col_Vat_Type,
    col_Payment_Methods,
    col_Entry,
    col_Created_by,
    col_Code,
    col_Fleet_No,
    col_Destination,
    col_Client_Name,
    col_Incharge,
    col_Department,
    col_Driver,
  ];

  static const String createtable = '''create table IF NOT EXISTS $table (
$col_Key  text,
$col_Vehicle_No text,
$col_Code text primary key,
$col_Start_Date  text,
$col_Start_Time  text,
$col_Return_Date  text,
$col_Return_Time  text,
$col_Amount  float,
$col_Client  int,
$col_Hire_Type  int,
$col_Vat_Type  int,
$col_Payment_Methods  int,
$col_Entry  int,
    $col_Created_by  text,
$col_Fleet_No  text,
$col_Destination  text,
$col_Client_Name  text,
$col_Incharge  text,
$col_Department  text,
$col_Driver  text

 )
''';

  @override
  fromMap_table(Map<String, dynamic> map) {
    return Hires.fromMap(map);
  }

  @override
  List<DbUpdate>? updates() {
    List<DbUpdate> update = [];
    update.add(DbUpdate(version: 14, updates: [createtable]));
    update.add(DbUpdate(
        version: 15,
        updates: ['ALTER TABLE $table ADD COLUMN $col_Fleet_No text ']));
    update.add(DbUpdate(version: 16, updates: [
      'ALTER TABLE $table ADD COLUMN $col_Destination text ',
      'ALTER TABLE $table ADD COLUMN $col_Client_Name text ',
      'ALTER TABLE $table ADD COLUMN $col_Incharge text ',
      'ALTER TABLE $table ADD COLUMN $col_Department text ',
      'ALTER TABLE $table ADD COLUMN $col_Driver text '
    ]));
    return update;
  }

  /// Sends the hire to the server and only returns true when the server
  /// confirmed the operation. On failure nothing is written locally.
  Future<bool> savetires(Hires hire) async {
    final LoggerService logger = Get.find();
    try {
      logger.info('[AddHire] savetires -> addHires payload: ${hire.toJson()}');
      debugPrint('[AddHire] savetires -> addHires payload: ${hire.toJson()}');
      final r = await ApiClient().postdata("addHires", hire.toJson());
      logger.info('[AddHire] savetires status: ${r.statusCode}');
      logger.info('[AddHire] savetires response body: ${r.body}');
      debugPrint('[AddHire] savetires status: ${r.statusCode}');
      debugPrint('[AddHire] savetires response body: ${r.body}');
      if (r.statusCode != 200) {
        return false;
      }

      // Parse the server response, but don't fail the whole save if only
      // the response body is unexpected - the server already processed it.
      try {
        Results2<Hires> results =
            Results2<Hires>.fromJson(r.body, Hires.fromMap);
        if (results.Code != 0) {
          return false;
        }
        if (results.Contents != null) {
          await Get.find<db_Provider>()
              .batchinsert(Hires.table, [results.Contents as Hires]);
        }
      } catch (e, stackTrace) {
        Errors().report(e as Exception);
      }

      // Refresh the local copy with what we sent.
      await Get.find<db_Provider>().batchinsert(Hires.table, [hire]);
      getthires();
      return true;
    } catch (e, stackTrace) {
      Errors().report(e as Exception);
      return false;
    }
  }

  Future<void> getthires() async {
    try {
      var request = Request(body: null);
      ApiClient().postdata("Hires", request.toJson()).then((r) async {
        if (r.statusCode == 200) {
          Results<Hires> results =
              Results<Hires>.fromJson(r.body, Hires.fromMap);
          if (results.Code == 0) {
            if (results.Contents != null) {
              Get.find<db_Provider>()
                  .batchinsert(Hires.table, results.Contents as List<Hires>);
              // for (TranTypes element in results.Contents as List<TranTypes>) {
              //   db.insert(TranTypes.table, element);
              // }
            }
          }
        }
      });
    } on Exception catch (e, stackTrace) {
      Errors().report(e as Exception);
      // Optionally, you can also log the stackTrace if needed
      // print(stackTrace);
    }

    Get.find<db_Provider>()
        .getalltrans(Hires.columns, Hires.table)
        .then((value) {
      print("value: $value");
      if (value.isNotEmpty) {
        List<Hires> tt = value.map((row) {
          return Hires.fromMap_fortable(row);
        }).toList();
        Get.find<HiresController>().hires.value = tt.toList();
      }
    });
  }

  @override
  Map<String, dynamic> toMap_fortable() {
    final dateFormat = DateFormat('HH:mm:ss');
    String? starttime, returnTime;
    try {
      starttime = dateFormat.format(Start_Time!);
      returnTime = dateFormat.format(Return_Time!);
    } catch (e) {}
    return <String, dynamic>{
      'Key': Key,
      'Vehicle_No': Vehicle_No,
      'Start_Date': formattedDate.format(Start_Date!),
      'Start_Time': starttime,
      'Return_Date': formattedDate.format(Return_Date!),
      'Return_Time': returnTime,
      'Amount': Amount,
      'Client': Client?.index,
      'Hire_Type': Hire_Type?.index,
      'Vat_Type': Vat_Type?.index,
      'Payment_Methods': Payment_Methods?.index,
      'Entry': Entry,
      'Created_by': Created_by,
      'Code': Code,
      'Fleet_No': Fleet_No,
      'Destination': Destination,
      'Client_Name': Client_Name,
      'Incharge': Incharge,
      'Department': Department,
      'Driver': Driver,
    };
  }
}
