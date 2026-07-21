// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:get/get.dart';
import 'package:t_matatu/controllers/main.dart';
import 'package:t_matatu/models/mappings.dart';
import 'package:t_matatu/network/Apis.dart';
import 'package:t_matatu/network/results/results.dart';
import 'package:t_matatu/pages/login.dart';
import 'package:t_matatu/providers/db.dart';

class Agent implements Tomaps, mapping {
  String? Key;
  String? Agent_Code;
  String? Customer_ID_No;
  String? Mobile_No;
  int? Status;
  String? Name;
  String? Account;
  String? Password;
  String? Constituency;
  int? Account_type;
  double? Account_Balance;
  Agent({
    this.Key,
    this.Agent_Code,
    this.Customer_ID_No,
    this.Mobile_No,
    this.Status,
    this.Name,
    this.Account,
    this.Password,
    this.Constituency,
    this.Account_type,
    this.Account_Balance,
  });

  static const String tableagents = 'agents';
  static const String col_Agent_Code = 'Agent_Code';
  static const String col_Customer_ID_No = 'Customer_ID_No';
  static const String col_Mobile_No = 'Mobile_No';
  static const String col_Status = 'Status';
  static const String col_Name = 'Name';
  static const String col_Account = 'Account';
  static const String col_Password = 'Password';
  static const String col_Constituency = 'Constituency';
  static const String col_Account_type = 'Account_type';
  static const String col_Account_Balance = 'Account_Balance';

  static const List<String> columns = [
    col_Agent_Code,
    col_Customer_ID_No,
    col_Mobile_No,
    col_Status,
    col_Name,
    col_Account,
    col_Password,
    col_Constituency,
    col_Account_type,
    col_Account_Balance
  ];

  static const String createtable = '''
create table IF NOT EXISTS $tableagents ( 
$col_Agent_Code text primary key , 
$col_Customer_ID_No	text ,
$col_Mobile_No	text ,
$col_Status	int ,
$col_Name	text ,
$col_Account	text ,
$col_Password	text ,
$col_Constituency	text ,
$col_Account_type	int ,
$col_Account_Balance	float )
''';
  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'Key': Key,
      'Agent_Code': Agent_Code,
      'Customer_ID_No': Customer_ID_No,
      'Mobile_No': Mobile_No,
      'Status': Status,
      'Name': Name,
      'Account': Account,
      'Password': Password,
      'Constituency': Constituency,
      'Account_type': Account_type,
      'Account_Balance': Account_Balance,
    };
  }

  factory Agent.fromMap(Map<String, dynamic> map) {
    return Agent(
      Key: map['Key'] != null ? map['Key'] as String : null,
      Agent_Code:
          map['Agent_Code'] != null ? map['Agent_Code'] as String : null,
      Customer_ID_No: map['Customer_ID_No'] != null
          ? map['Customer_ID_No'] as String
          : null,
      Mobile_No: map['Mobile_No'] != null ? map['Mobile_No'] as String : null,
      Status: map['Status'] != null ? map['Status'] as int : null,
      Name: map['Name'] != null ? map['Name'] as String : null,
      Account: map['Account'] != null ? map['Account'] as String : null,
      Password: map['Password'] != null ? map['Password'] as String : null,
      Constituency:
          map['Constituency'] != null ? map['Constituency'] as String : null,
      Account_type:
          map['Account_type'] != null ? map['Account_type'] as int : null,
      Account_Balance: map['Account_Balance'] != null
          ? (map['Account_Balance'] as num).toDouble()
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Agent.fromJson(String source) =>
      Agent.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  fromMap_table(Map<String, dynamic> map) {
    return Agent(
      Agent_Code:
          map['Agent_Code'] != null ? map['Agent_Code'] as String : null,
      Customer_ID_No: map['Customer_ID_No'] != null
          ? map['Customer_ID_No'] as String
          : null,
      Mobile_No: map['Mobile_No'] != null ? map['Mobile_No'] as String : null,
      Status: map['Status'] != null ? map['Status'] as int : null,
      Name: map['Name'] != null ? map['Name'] as String : null,
      Account: map['Account'] != null ? map['Account'] as String : null,
      Password: map['Password'] != null ? map['Password'] as String : null,
      Constituency:
          map['Constituency'] != null ? map['Constituency'] as String : null,
      Account_type:
          map['Account_type'] != null ? map['Account_type'] as int : null,
      Account_Balance: map['Account_Balance'] != null
          ? (map['Account_Balance'] as num).toDouble()
          : null,
    );
  }

  @override
  toMap_fortable() {
    return <String, dynamic>{
      'Agent_Code': Agent_Code,
      'Customer_ID_No': Customer_ID_No,
      'Mobile_No': Mobile_No,
      'Status': Status,
      'Name': Name,
      'Account': Account,
      'Password': Password,
      'Constituency': Constituency,
      'Account_type': Account_type,
      'Account_Balance': Account_Balance,
    };
  }

  Future<void> updatcurrentagent(List<Agent> agent) async {
    Agent? ag = agent.firstWhereOrNull((element) =>
        element.Agent_Code ==
            Get.find<MainController>().agent.value.Agent_Code &&
        element.Status == 2);
    if (ag != null) {
      Get.find<MainController>().agent.value = ag;
    } else {
      Get.find<MainController>().agent.value = Agent();
      Get.to(() => Login());
    }
  }

  Future<void> getagents() async {
    ApiClient().postdata("agents", null).then((r) async {
      if (r.statusCode == 200) {
        Results<Agent> results = Results<Agent>.fromJson(r.body, Agent.fromMap);
        if (results.Code == 0) {
          if (results.Contents != null && results.Contents!.isNotEmpty) {
            await Get.find<db_Provider>().batchdelete(Agent.tableagents);
            await Get.find<db_Provider>().batchinsert(
                Agent.tableagents, results.Contents as List<Agent>);
            if (Get.find<MainController>().agent.value.Agent_Code != null) {
              updatcurrentagent(results.Contents as List<Agent>);
            }
          }
        }
      }
    }).catchError((e, stackTrace) {
      print('[MATATU-API] getagents error: $e');
      print('[MATATU-API] $stackTrace');
    });
  }
}
