// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:convert';

import 'package:get/get.dart';
import 'package:t_matatu/controllers/expenses/expense_controller.dart';

import '../../network/Apis.dart';
import '../../network/errors.dart';
import '../../network/request.dart';
import '../../network/results/results.dart';
import '../../providers/db.dart';
import '../mappings.dart';

class Expenses implements mapping, Tomaps, AbsDbUpdates, data<Expenses> {
  String? Key;
  String? Code;
  String? Description;

  Expenses({
    this.Key,
    this.Code,
    this.Description,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'Key': Key,
      'Code': Code,
      'Description': Description,
    };
  }

  factory Expenses.fromMap(Map<String, dynamic> map) {
    return Expenses(
      Key: map['Key'] != null ? map['Key'] as String : null,
      Code: map['Code'] != null ? map['Code'] as String : null,
      Description:
          map['Description'] != null ? map['Description'] as String : null,
    );
  }

  @override
  String toString() {
    return '$Code $Description';
  }

  String toJson() => json.encode(toMap());

  factory Expenses.fromJson(String source) =>
      Expenses.fromMap(json.decode(source) as Map<String, dynamic>);

  static const String table = 'Expenses';
  static const String col_Key = 'Key';
  static const String col_Code = 'Code';
  static const String col_Description = 'Description';

  static const List<String> columns = [
    col_Key,
    col_Code,
    col_Description,
  ];

  @override
  static const String createtable = '''create table IF NOT EXISTS $table (
$col_Key  text,
$col_Code text primary key ,
$col_Description  text
 )
''';

  @override
  fromMap_table(Map<String, dynamic> map) {
    return Expenses.fromMap(map);
  }

  @override
  List<DbUpdate>? updates() {
    List<DbUpdate> update = [];
    update.add(DbUpdate(version: 7, updates: [createtable]));
    return update;
  }

  @override
  toMap_fortable() {
    return <String, dynamic>{
      'Key': Key,
      'Code': Code,
      'Description': Description,
    };
  }

  Future<void> download() async {
    try {
      var request = Request(body: null);
      ApiClient().postdata("expenses", request.toJson()).then((r) async {
        if (r.statusCode == 200) {
          Results<Expenses> results =
              Results<Expenses>.fromJson(r.body, Expenses.fromMap);
          if (results.Code == 0) {
            if (results.Contents != null) {
              await Get.find<db_Provider>().batchdelete(Expenses.table);
              Get.find<db_Provider>().batchinsert(
                  Expenses.table, results.Contents as List<Expenses>);
              Get.find<ExpenseController>().all.value =
                  results.Contents as List<Expenses>;
            }
          }
        }
      });
    } on Exception catch (e) {
      Errors().report(e);
    }
  }

  @override
  Future<List<Expenses>> getall() async {
    final rows = await Get.find<db_Provider>().getalltrans(columns, table);
    return rows.map((row) => Expenses.fromMap(row)).toList();
  }
}
