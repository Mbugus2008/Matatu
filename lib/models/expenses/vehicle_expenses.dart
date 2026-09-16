import 'dart:convert';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:t_matatu/models/mappings.dart';
import 'package:t_matatu/network/Apis.dart';
import 'package:t_matatu/network/results/results.dart';
import 'package:t_matatu/providers/db.dart';

class Vehicle_Expenses
    implements mapping, Tomaps, AbsDbUpdates, data<Vehicle_Expenses> {
  String? Key;
  String? Code;
  String? Vehicle_No;
  DateTime? Date;
  bool? DateSpecified;
  String? Expense;
  String? Description;
  String? Created_By;
  double? Amount;
  bool? AmountSpecified;
  String? Fleet_No;

  /// False while the row only exists on the device. Set to true once BC has
  /// accepted it, so Post All knows what still needs sending.
  bool sent = false;

  Vehicle_Expenses({
    this.Key,
    this.Code,
    this.Vehicle_No,
    this.Date,
    this.DateSpecified,
    this.Expense,
    this.Description,
    this.Created_By,
    this.Amount,
    this.AmountSpecified,
    this.Fleet_No,
    this.sent = false,
  });

  factory Vehicle_Expenses.fromMap(Map<String, dynamic> map) {
    return Vehicle_Expenses(
      Key: map['Key']?.toString(),
      Code: map['Code']?.toString(),
      Vehicle_No: map['Vehicle_No']?.toString(),
      Date: _parseDate(map['Date']),
      DateSpecified: map['DateSpecified'] as bool?,
      Expense: map['Expense']?.toString(),
      Description: map['Description']?.toString(),
      Created_By: map['Created_By']?.toString(),
      Amount: map['Amount'] != null ? (map['Amount'] as num).toDouble() : null,
      AmountSpecified: map['AmountSpecified'] as bool?,
      Fleet_No: map['Fleet_No']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'Key': Key,
      'Code': Code,
      'Vehicle_No': Vehicle_No,
      'Date': Date?.toIso8601String(),
      'DateSpecified': DateSpecified,
      'Expense': Expense,
      'Description': Description,
      'Created_By': Created_By,
      'Amount': Amount,
      'AmountSpecified': AmountSpecified,
      'Fleet_No': Fleet_No,
    };
  }

  factory Vehicle_Expenses.fromJson(String source) =>
      Vehicle_Expenses.fromMap(json.decode(source) as Map<String, dynamic>);

  String toJson() => json.encode(toMap());

  @override
  Vehicle_Expenses fromMap_table(Map<String, dynamic> map) {
    return Vehicle_Expenses.fromMap_db(map);
  }

  @override
  Map<String, dynamic> toMap_fortable() {
    return {
      'Key': Key,
      'Code': Code,
      'Vehicle_No': Vehicle_No,
      'Date': Date?.millisecondsSinceEpoch,
      'DateSpecified': DateSpecified == true ? 1 : 0,
      'Expense': Expense,
      'Description': Description,
      'Created_By': Created_By,
      'Amount': Amount,
      'AmountSpecified': AmountSpecified == true ? 1 : 0,
      'Fleet_No': Fleet_No,
      'sent': sent ? 1 : 0,
    };
  }

  factory Vehicle_Expenses.fromMap_db(Map<String, dynamic> map) {
    return Vehicle_Expenses(
      Key: map['Key']?.toString(),
      Code: map['Code']?.toString(),
      Vehicle_No: map['Vehicle_No']?.toString(),
      Date: _parseDate(map['Date']),
      DateSpecified: (map['DateSpecified'] ?? 0) == 1,
      Expense: map['Expense']?.toString(),
      Description: map['Description']?.toString(),
      Created_By: map['Created_By']?.toString(),
      Amount: map['Amount'] != null ? (map['Amount'] as num).toDouble() : null,
      AmountSpecified: (map['AmountSpecified'] ?? 0) == 1,
      Fleet_No: map['Fleet_No']?.toString(),
      sent: (map['sent'] ?? 0) == 1,
    );
  }

  /// Dates reach this model in three shapes: int milliseconds from the local
  /// table, NAV's MM/dd/yyyy HH:mm:ss from the API, and ISO-8601 from JSON.
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return DateFormat('MM/dd/yyyy HH:mm:ss', 'en_US').tryParse(text) ??
        DateTime.tryParse(text);
  }

  static const String table = 'Vehicle_Expenses';
  static const String col_Key = 'Key';
  static const String col_Code = 'Code';
  static const String col_Vehicle_No = 'Vehicle_No';
  static const String col_Date = 'Date';
  static const String col_DateSpecified = 'DateSpecified';
  static const String col_Expense = 'Expense';
  static const String col_Description = 'Description';
  static const String col_Created_By = 'Created_By';
  static const String col_Amount = 'Amount';
  static const String col_AmountSpecified = 'AmountSpecified';
  static const String col_Fleet_No = 'Fleet_No';
  static const String col_sent = 'sent';

  static const List<String> columns = [
    col_Key,
    col_Code,
    col_Vehicle_No,
    col_Date,
    col_DateSpecified,
    col_Expense,
    col_Description,
    col_Created_By,
    col_Amount,
    col_AmountSpecified,
    col_Fleet_No,
    col_sent,
  ];

  static const String createtable = '''create table IF NOT EXISTS $table (
$col_Key text,
$col_Code text primary key,
$col_Vehicle_No text,
$col_Date int,
$col_DateSpecified int,
$col_Expense text,
$col_Description text,
$col_Created_By text,
$col_Amount float,
$col_AmountSpecified int,
$col_Fleet_No text,
$col_sent integer DEFAULT 0
)
''';

  @override
  List<DbUpdate>? updates() {
    return [DbUpdate(version: 18, updates: [createtable])];
  }

  @override
  Future<List<Vehicle_Expenses>> getall() async {
    final rows = await Get.find<db_Provider>()
        .getalltrans(Vehicle_Expenses.columns, Vehicle_Expenses.table);
    return rows.map(Vehicle_Expenses.fromMap_db).toList();
  }

  // ─── Local-first sync ───

  /// BC numbers entries on this page as VE + milliseconds, so a row captured
  /// on the device can use the same shape and BC keeps it on insert.
  static String newCode() => 'VE${DateTime.now().millisecondsSinceEpoch}';

  /// Rows that only exist on this device.
  static Future<List<Vehicle_Expenses>> pending() async {
    final rows = await Get.find<db_Provider>()
        .getdata(table, columns, '$col_sent = 0 OR $col_sent IS NULL');
    return rows.map(Vehicle_Expenses.fromMap_db).toList();
  }

  Future<Vehicle_Expenses> saveLocal() async {
    Code ??= newCode();
    await Get.find<db_Provider>().insert(table, this);
    return this;
  }

  static Future<void> deleteLocal(String? code) async {
    if (code == null) return;
    await Get.find<db_Provider>().deletedata(table, '$col_Code = ?', [code]);
  }

  /// Posts everything still pending. Returns how many rows BC accepted.
  static Future<int> postPending() async => postRows(await pending());

  /// Sends [rows] in one request through setexpensesbatch. Rows BC rejected
  /// stay unsynced, so a partial success is reported rather than thrown.
  static Future<int> postRows(List<Vehicle_Expenses> rows) async {
    if (rows.isEmpty) return 0;
    final payload = json.encode(rows.map((r) => r.toMap()).toList());
    final response = await ApiClient().postdata('setexpensesbatch', payload);
    if (response.statusCode != 200) {
      throw Exception('Server error ${response.statusCode}');
    }
    final results =
        Results<Vehicle_Expenses>.fromJson(response.body, Vehicle_Expenses.fromMap);
    if (results.Code != 0) {
      throw Exception(results.Desc ?? 'Post failed');
    }
    var synced = 0;
    for (final server in results.Contents ?? <Vehicle_Expenses>[]) {
      final local = _matchLocal(rows, server);
      if (local == null) continue;
      if (server.Code != null && server.Code != local.Code) {
        // BC renumbered the entry: move the local row onto the new code
        // instead of leaving a duplicate behind.
        await deleteLocal(local.Code);
        local.Code = server.Code;
      }
      local.Key = server.Key ?? local.Key;
      local.sent = true;
      await Get.find<db_Provider>().insert(table, local);
      synced++;
    }
    return synced;
  }

  static Vehicle_Expenses? _matchLocal(
      List<Vehicle_Expenses> rows, Vehicle_Expenses server) {
    for (final row in rows) {
      if (server.Code != null && row.Code == server.Code) return row;
      if (server.Key != null && row.Key == server.Key) return row;
    }
    return null;
  }

  @override
  String toString() {
    return 'Vehicle_Expenses(Key: $Key, Code: $Code, Vehicle_No: $Vehicle_No, Date: $Date, DateSpecified: $DateSpecified, Expense: $Expense, Description: $Description, Created_By: $Created_By, Amount: $Amount, AmountSpecified: $AmountSpecified, Fleet_No: $Fleet_No)';
  }
}

typedef Vehicle_expenses = Vehicle_Expenses;
