// ignore_for_file: public_member_api_docs, sort_constructors_first
// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:get/get.dart';
import 'package:t_matatu/models/mappings.dart';
import 'package:t_matatu/models/vehicles/vehicle.dart';

import '../network/Apis.dart';
import '../network/request.dart';
import '../network/results/results.dart';
import '../providers/db.dart';

class Tamounts implements Tomaps, mapping, AbsDbUpdates {
  String? Key;
  String? Code;
  vehicle_type? Vehicle_Type;
  double? Amount;
  String? Name;
  Tamounts({
    this.Key,
    this.Code,
    this.Vehicle_Type,
    this.Amount,
    this.Name,
  });

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'Key': Key,
      'Code': Code,
      'Vehicle_Type': Vehicle_Type!.index,
      'Amount': Amount,
      'Name': Name,
    };
  }

  factory Tamounts.fromMap(Map<String, dynamic> map) {
    return Tamounts(
      Key: map['Key'] != null ? map['Key'] as String : null,
      Code: map['Code'] != null ? map['Code'] as String : null,
      Vehicle_Type: map['Vehicle_Type'] != null
          ? vehicle_type.values[(map['Vehicle_Type'])]
          : null,
      Amount: map['Amount'] != null ? map['Amount'] as double : null,
      Name: map['Name'] != null ? map['Name'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Tamounts.fromJson(String source) =>
      Tamounts.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  fromMap_table(Map<String, dynamic> map) {
    // TODO: implement fromMap_table
    return Tamounts.fromMap(map);
  }

  @override
  toMap_fortable() {
    return toMap();
  }

//db
  static const String table = 'TAmounts';
  static const String colKey = "Key";
  static const String colCode = "Code";
  static const String colVehicleType = "Vehicle_Type";
  static const String colAmount = "Amount";
  static const String colName = "Name";
  static const List<String> columns = [
    colKey,
    colCode,
    colVehicleType,
    colAmount,
    colName,
  ];

  static const String createtable = '''create table IF NOT EXISTS $table (
$colKey  text,
$colCode text  ,
$colVehicleType  int,
$colAmount  float,
$colName  text,
PRIMARY KEY ($colCode, $colVehicleType)

 )
''';
  @override
  List<DbUpdate>? updates() {
    List<DbUpdate> update = [];

    update.add(DbUpdate(version: 6, updates: [createtable]));

    return update;
  }
//db

  Future<void> getttypesamounts() async {
    var request = Request(body: null);
    ApiClient().postdata("transtypesamounts", request.toJson()).then((r) async {
      if (r.statusCode == 200) {
        Results<Tamounts> results =
            Results<Tamounts>.fromJson(r.body, Tamounts.fromMap);
        if (results.Code == 0) {
          if (results.Contents != null) {
            Get.find<db_Provider>().batchinsert(
                Tamounts.table, results.Contents as List<Tamounts>);
            // for (TranTypes element in results.Contents as List<TranTypes>) {
            //   db.insert(TranTypes.table, element);
            // }
          }
        }
      }
    });
  }
}
