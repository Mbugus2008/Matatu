// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:convert';

import 'package:get/get.dart';
import 'package:t_matatu/controllers/Members.dart';
import 'package:t_matatu/models/mappings.dart';
import 'package:t_matatu/network/Apis.dart';
import 'package:t_matatu/network/request.dart';
import 'package:t_matatu/network/results/results.dart';
import 'package:t_matatu/providers/db.dart';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class Member implements mapping, Tomaps, AbsDbUpdates {
  String? Key;
  String? No;
  String? Name;
  String? Phone_No;
  String? ID_No;
  String? E_Mail;
  status? Status;
  String? Customer_Posting_Group;
  double? Loans;
  Crew_type? Crew_Type;
  String? Vehicle;

  Member({
    this.Key,
    this.No,
    this.Name,
    this.Phone_No,
    this.ID_No,
    this.E_Mail,
    this.Status,
    this.Customer_Posting_Group,
    this.Loans = 0,
    this.Crew_Type,
    this.Vehicle,
  });

  @override
  String toString() {
    return '$No $Name $Phone_No $ID_No $Vehicle $Crew_Type';
  }

  @override
  Map<String, dynamic> toMap_fortable() {
    return toMap();
    // <String, dynamic>{
    //   'Key': Key,
    //   'No': No,
    //   'Name': Name,
    //   'Phone_No': Phone_No,
    //   'ID_No': ID_No,
    //   'E_Mail': E_Mail,
    //   'Status': Status?.index,
    //   'Customer_Posting_Group': Customer_Posting_Group,
    //   'Vehicle': Vehicle,
    //   'Loans': Loans,
    //   'Crew_Type': Crew_Type?.index,
    // };
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'Key': Key,
      'No': No,
      'Name': Name,
      'Phone_No': Phone_No,
      'ID_No': ID_No,
      'E_Mail': E_Mail,
      'Status': Status?.index,
      'Customer_Posting_Group': Customer_Posting_Group,
      'Vehicle': Vehicle,
      'Loans': Loans,
      'Crew_Type': Crew_Type?.index,
    };
  }

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      Key: map['Key'] != null ? map['Key'] as String : null,
      No: map['No'] ?? '',
      Name: map['Name'] ?? '',
      Phone_No: map['Phone_No'] != null ? map['Phone_No'] as String : null,
      ID_No: map['ID_No'] != null ? map['ID_No'] as String : null,
      E_Mail: map['E_Mail'] != null ? map['E_Mail'] as String : null,
      Customer_Posting_Group: map['Customer_Posting_Group'] != null
          ? map['Customer_Posting_Group'] as String
          : null,
      Status:
          map['Status'] != null ? status.values[(map['Status'] as int)] : null,
      Crew_Type: map['Crew_Type'] != null
          ? Crew_type.values[(map['Crew_Type'] as int)]
          : null,
      Vehicle: map['Vehicle'] != null ? map['Vehicle'] as String : null,
      Loans: map['Loans'] != null ? (map['Loans'] as num).toDouble() : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Member.fromJson(String source) =>
      Member.fromMap(json.decode(source) as Map<String, dynamic>);

  static const String table = 'Members';
  static const String col_Key = 'Key';
  static const String col_No = 'No';
  static const String col_Name = 'Name';
  static const String col_Phone_No = 'Phone_No';
  static const String col_ID_No = 'ID_No';
  static const String col_E_Mail = 'E_Mail';
  static const String col_Status = 'Status';
  static const String col_Customer_Posting_Group = 'Customer_Posting_Group';
  static const String col_Vehicle = 'Vehicle';
  static const String col_Loans = 'Loans';
  static const String col_Crew_Type = 'Crew_Type';

  static const List<String> columns = [
    col_Key,
    col_No,
    col_Name,
    col_Phone_No,
    col_ID_No,
    col_E_Mail,
    col_Status,
    col_Customer_Posting_Group,
    col_Crew_Type,
    col_Vehicle
  ];

  static const String createtable = '''create table IF NOT EXISTS $table (
 $col_Key text,
$col_No text primary key ,
$col_Name text,
$col_Phone_No text,
$col_ID_No text,
$col_E_Mail text,
$col_Customer_Posting_Group text,
$col_Status int,
$col_Crew_Type int,
$col_Loans float,
$col_Vehicle text
)
''';

  @override
  fromMap_table(Map<String, dynamic> map) {
    Member.fromMap(map);
  }

  @override
  List<DbUpdate>? updates() {
    List<DbUpdate> update = [];

    update.add(DbUpdate(version: 1, updates: [
      'ALTER TABLE $table ADD COLUMN $col_Crew_Type int ',
      'ALTER TABLE $table ADD COLUMN $col_Loans float ',
      'ALTER TABLE $table ADD COLUMN $col_Vehicle text'
    ]));
    return update;
  }

  Future<void> getmembers() async {
    bool hasdata = true;
    String? bookmark;
    int? size = 50;
    var request = Request(body: null, bookmark: bookmark, size: size);
    while (hasdata) {
      await ApiClient().postdata("members", request.toJson()).then((r) async {
        if (r.statusCode == 200) {
          Results<Member> results =
              Results<Member>.fromJson(r.body, Member.fromMap);
          if (results.Code == 0) {
            if (results.Contents != null) {
              hasdata = results.Contents!.isNotEmpty;
              if (results.Contents!.isNotEmpty) {
                await Get.find<db_Provider>().batchinsert(
                    Member.table, results.Contents as List<Member>);
                bookmark = results.Contents!.last.Key;
                request = Request(body: null, bookmark: bookmark, size: size);
              }
            }
          } else {
            if (results.Desc == 'The operation has timed out') {
              size = (size! / 2).round();
            }
            hasdata = false;
          }
        } else {
          hasdata = false;
        }
        Get.find<MemberController>().initialize;
      });
    }
  }
}

enum status {
  Active,
  Dormant,
}

enum Crew_type {
  /// <remarks/>
  Driver,

  /// <remarks/>
  Conductor,
}
