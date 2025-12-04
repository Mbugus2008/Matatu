// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:t_matatu/models/mappings.dart';
import 'package:t_matatu/network/Apis.dart';
import 'package:t_matatu/network/request.dart';
import 'package:t_matatu/network/results/results.dart';
import 'package:t_matatu/providers/db.dart';
import 'package:t_matatu/providers/dbupdates.dart' as dbu;

// ignore_for_file: public_member_api_docs, sort_constructors_first
class Account_Types implements mapping, Tomaps, AbsDbUpdates {
  String? Key;
  int? Account_type;
  String? Transaction_Type;
  String? Description;
  Account_Types({
    this.Key,
    this.Account_type,
    this.Transaction_Type,
    this.Description,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'Key': Key,
      'Account_type': Account_type,
      'Transaction_Type': Transaction_Type,
      'Description': Description,
    };
  }

  factory Account_Types.fromMap(Map<String, dynamic> map) {
    return Account_Types(
      Key: map['Key'] != null ? map['Key'] as String : null,
      Account_type:
          map['Account_type'] != null ? map['Account_type'] as int : null,
      Transaction_Type: map['Transaction_Type'] != null
          ? map['Transaction_Type'] as String
          : null,
      Description:
          map['Description'] != null ? map['Description'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Account_Types.fromJson(String source) =>
      Account_Types.fromMap(json.decode(source) as Map<String, dynamic>);

  static const String table = 'AccountTypes';
  static const String col_Key = 'Key';
  static const String col_Account_type = 'Account_type';
  static const String col_Transaction_Type = 'Transaction_Type';
  static const String col_Description = 'Description';

  static const List<String> columns = [
    col_Key,
    col_Account_type,
    col_Transaction_Type,
    col_Description,
  ];

  static const String createtable = '''create table IF NOT EXISTS $table (
$col_Key  text,
$col_Account_type text,
$col_Transaction_Type  text,
$col_Description  text,
PRIMARY KEY ($col_Account_type, $col_Transaction_Type)
 )
''';

  @override
  List<dbu.DbUpdate>? updates() {
    return dbu.getDbUpdatesForTable(table);
  }

  @override
  fromMap_table(Map<String, dynamic> map) {
    // TODO: implement fromMap_table
    return Account_Types.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap_fortable() {
    return toMap();
  }

  Future<void> get_account_Types() async {
    var request = Request(body: null);
    ApiClient().postdata("transtypes", request.toJson()).then((r) async {
      if (r.statusCode == 200) {
        Results<Account_Types> results =
            Results<Account_Types>.fromJson(r.body, Account_Types.fromMap);
        if (results.Code == 0) {
          if (results.Contents != null) {
            db_Provider().batchdelete(Account_Types.table);
            db_Provider().batchinsert(
                Account_Types.table, results.Contents as List<Account_Types>);
            // for (TranTypes element in results.Contents as List<TranTypes>) {
            //   db.insert(TranTypes.table, element);
            // }
          }
        }
      }
    });
  }
}
