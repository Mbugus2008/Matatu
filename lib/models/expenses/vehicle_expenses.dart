import 'dart:convert';

import 'package:get/get.dart';
import 'package:t_matatu/models/mappings.dart';
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
  });

  factory Vehicle_Expenses.fromMap(Map<String, dynamic> map) {
    return Vehicle_Expenses(
      Key: map['Key']?.toString(),
      Code: map['Code']?.toString(),
      Vehicle_No: map['Vehicle_No']?.toString(),
      Date: map['Date'] != null
          ? DateTime.tryParse(map['Date'].toString())
          : null,
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
    };
  }

  factory Vehicle_Expenses.fromMap_db(Map<String, dynamic> map) {
    return Vehicle_Expenses(
      Key: map['Key']?.toString(),
      Code: map['Code']?.toString(),
      Vehicle_No: map['Vehicle_No']?.toString(),
      Date: map['Date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['Date'] as int)
          : null,
      DateSpecified: (map['DateSpecified'] ?? 0) == 1,
      Expense: map['Expense']?.toString(),
      Description: map['Description']?.toString(),
      Created_By: map['Created_By']?.toString(),
      Amount: map['Amount'] != null ? (map['Amount'] as num).toDouble() : null,
      AmountSpecified: (map['AmountSpecified'] ?? 0) == 1,
      Fleet_No: map['Fleet_No']?.toString(),
    );
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
$col_Fleet_No text
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

  @override
  String toString() {
    return 'Vehicle_Expenses(Key: $Key, Code: $Code, Vehicle_No: $Vehicle_No, Date: $Date, DateSpecified: $DateSpecified, Expense: $Expense, Description: $Description, Created_By: $Created_By, Amount: $Amount, AmountSpecified: $AmountSpecified, Fleet_No: $Fleet_No)';
  }
}

typedef Vehicle_expenses = Vehicle_Expenses;
