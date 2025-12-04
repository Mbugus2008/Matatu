// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:t_matatu/models/mappings.dart';
import 'package:t_matatu/providers/db.dart';
import 'package:t_matatu/providers/dbupdates.dart' as dbu;

import '../network/Apis.dart';
import '../network/Errors.dart';
import '../network/request.dart';
import '../network/results/results.dart';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class TranTypes implements mapping, Tomaps, AbsDbUpdates {
  String? Key;
  String? Code;
  String? Name;
  String? Name2;
  bool? Active;
  bool? Attach_to_vehicle;
  int? Order;
  String? Activity;
  String? Account;
  double? Amount;
  String? Customer_Posting_Group;
  bool? Checked;
  double? Amountedited = 0;
  double? VehicleAmount = 0;
  double? Amounttoday = 0;

  TextEditingController eAmount = TextEditingController();
  final FocusNode FocusNodes = FocusNode();
  TranTypes({
    this.Key,
    this.Code,
    this.Name,
    this.Name2,
    this.Active,
    this.Attach_to_vehicle,
    this.Order,
    this.Activity,
    this.Account,
    this.Amount,
    this.Customer_Posting_Group,
    this.Checked = false,
    this.Amountedited = 0,
    this.VehicleAmount = 0,
    this.Amounttoday = 0,
  });
  @override
  String toString() {
    return '$Code $Name $Order $Customer_Posting_Group $Amountedited $Amounttoday $VehicleAmount';
  }

  bool operator ==(dynamic other) =>
      other != null && other is TranTypes && this.Code == other.Code;

  @override
  int get hashCode => super.hashCode;

  List<String?> Codes(List<TranTypes> t) => t.map((obj) => obj.Code).toList();

  @override
  Map<String, dynamic> toMap_fortable() {
    return <String, dynamic>{
      'Key': Key,
      'Code': Code,
      'Name': Name,
      'Active': Active,
      'Attach_to_vehicle': Attach_to_vehicle,
      'Order_': Order,
      'Activity': Activity,
      'Account': Account,
      'Amount': Amount,
      'Customer_Posting_Group': Customer_Posting_Group
    };
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'Key': Key,
      'Code': Code,
      'Name': Name,
      'Name2': Name,
      'Active': Active,
      'Attach_to_vehicle': Attach_to_vehicle,
      'Order': Order,
      'Activity': Activity,
      'Account': Account,
      'Amount': Amount,
      'Customer_Posting_Group': Customer_Posting_Group
    };
  }

  factory TranTypes.fromMap(Map<String, dynamic> map) {
    return TranTypes(
      Key: map['Key'] != null ? map['Key'] as String : null,
      Code: map['Code'] != null ? map['Code'] as String : null,
      Name: map['Name'] != null ? map['Name'] as String : null,
      Name2: map['Name'] != null ? map['Name'] as String : null,
      Active: map['Active'] != null ? map['Active'] as bool : null,
      Attach_to_vehicle: map['Attach_to_vehicle'] != null
          ? map['Attach_to_vehicle'] as bool
          : null,
      Order: map['Order'] != null ? map['Order'] as int : null,
      Activity: map['Activity'] != null ? map['Activity'] as String : null,
      Account: map['Account'] != null ? map['Account'] as String : null,
      Amount: map['Amount'] != null ? (map['Amount'] as num).toDouble() : null,
      Customer_Posting_Group: map['Customer_Posting_Group'] != null
          ? map['Customer_Posting_Group'] as String
          : null,
    );
  }
  factory TranTypes.fromMap_fortable(Map<String, dynamic> map) {
    return TranTypes(
      Key: map['Key'] != null ? map['Key'] as String : null,
      Code: map['Code'] != null ? map['Code'] as String : null,
      Name: map['Name'] != null ? map['Name'] as String : null,
      Name2: map['Name'] != null ? map['Name'] as String : null,
      Active:
          map['Active'] != null ? (map['Active'] == 0 ? false : true) : null,
      Attach_to_vehicle: map['Attach_to_vehicle'] != null
          ? map['Attach_to_vehicle'] == 0
              ? false
              : true
          : null,
      Order: map['Order_'] != null ? map['Order_'] as int : null,
      Activity: map['Activity'] != null ? map['Activity'] as String : null,
      Account: map['Account'] != null ? map['Account'] as String : null,
      Amount: map['Amount'] != null ? map['Amount'] as double : null,
      Customer_Posting_Group: map['Customer_Posting_Group'] != null
          ? map['Customer_Posting_Group'] as String
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory TranTypes.fromJson(String source) =>
      TranTypes.fromMap(json.decode(source) as Map<String, dynamic>);

  static const String table = 'TranTypes';
  static const String col_Key = 'Key';
  static const String col_Code = 'Code';
  static const String col_Name = 'Name';
  static const String col_Active = 'Active';
  static const String col_Attach_to_vehicle = 'Attach_to_vehicle';
  static const String col_Order = 'Order_';
  static const String col_Activity = 'Activity';
  static const String col_Account = 'Account';
  static const String col_Amount = 'Amount';
  static const String col_Customer_Posting_Group = 'Customer_Posting_Group';

  static const List<String> columns = [
    col_Key,
    col_Code,
    col_Name,
    col_Active,
    col_Attach_to_vehicle,
    col_Order,
    col_Activity,
    col_Account,
    col_Amount,
    col_Customer_Posting_Group
  ];

  static const String createtable = '''create table IF NOT EXISTS $table (
$col_Key  text,
$col_Code text primary key ,
$col_Name  text,
$col_Active  int,
$col_Attach_to_vehicle  int,
$col_Order  int,
$col_Activity  text,
$col_Account  text,
$col_Customer_Posting_Group text,
$col_Amount  float

 )
''';

  @override
  fromMap_table(Map<String, dynamic> map) {
    return TranTypes.fromMap(map);
  }

  @override
  List<dbu.DbUpdate>? updates() {
    return dbu.getDbUpdatesForTable(table);
  }

  Future<void> getttypes() async {
    try {
      var request = Request(body: null);
      ApiClient().postdata("transtypes", request.toJson()).then((r) async {
        if (r.statusCode == 200) {
          Results<TranTypes> results =
              Results<TranTypes>.fromJson(r.body, TranTypes.fromMap);
          if (results.Code == 0) {
            if (results.Contents != null) {
              Get.find<db_Provider>().batchdelete(TranTypes.table);
              final filteredList = (results.Contents as List<TranTypes>)
                  .where((item) => item.Name != null)
                  .toList();
              Get.find<db_Provider>()
                  .batchinsert(TranTypes.table, filteredList);
              // for (TranTypes element in results.Contents as List<TranTypes>) {
              //   db.insert(TranTypes.table, element);
              // }
            }
          }
        }
      });
    } on Exception catch (e) {
      Errors().report(e);
    }
  }

  TranTypes copyWith({
    String? Key,
    String? Code,
    String? Name,
    String? Name2,
    bool? Active,
    bool? Attach_to_vehicle,
    int? Order,
    String? Activity,
    String? Account,
    double? Amount,
    String? Customer_Posting_Group,
    bool? Checked,
    double? Amountedited,
    double? VehicleAmount,
    double? Amounttoday,
  }) {
    return TranTypes(
      Key: Key ?? this.Key,
      Code: Code ?? this.Code,
      Name: Name ?? this.Name,
      Name2: Name2 ?? this.Name2,
      Active: Active ?? this.Active,
      Attach_to_vehicle: Attach_to_vehicle ?? this.Attach_to_vehicle,
      Order: Order ?? this.Order,
      Activity: Activity ?? this.Activity,
      Account: Account ?? this.Account,
      Amount: Amount ?? this.Amount,
      Customer_Posting_Group:
          Customer_Posting_Group ?? this.Customer_Posting_Group,
      Checked: Checked ?? this.Checked,
      Amountedited: Amountedited ?? this.Amountedited,
      VehicleAmount: VehicleAmount ?? this.VehicleAmount,
      Amounttoday: Amounttoday ?? this.Amounttoday,
    );
  }
}
