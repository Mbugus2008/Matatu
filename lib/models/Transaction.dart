// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:t_matatu/init.dart';
import 'package:t_matatu/models/mappings.dart';

import 'Utils/util.dart';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class Trans implements mapping, Tomaps {
  String? Key;
  String? Document_No;
  DateTime? Transaction_Date;
  String? Account_No;
  String? Description;
  double? Amount;
  bool? Posted;
  DateTime? Transaction_Time;
  String? Messages;
  String? OTTN;
  String? Transaction_Location;
  String? Transaction_By;
  String? Agent_Code;
  String? Loan_No;
  String? Account_Name;
  String? Telephone;
  String? Id_No;
  String? Constituency;
  String? Ward;
  String? Type;
  bool? sent;
  DateTime? Creation_time;
  Trans({
    this.Key,
    this.Document_No,
    this.Transaction_Date,
    this.Account_No,
    this.Description,
    this.Amount = 0,
    this.Posted,
    this.Transaction_Time,
    this.Messages,
    this.OTTN,
    this.Transaction_Location,
    this.Transaction_By,
    this.Agent_Code,
    this.Loan_No,
    this.Account_Name,
    this.Telephone,
    this.Id_No,
    this.Constituency,
    this.Ward,
    this.Type,
    this.sent,
    this.Creation_time,
  });
  bool operator ==(dynamic other) =>
      other != null &&
      other is Trans &&
      Document_No == other.Document_No &&
      OTTN == other.OTTN;

  @override
  int get hashCode => super.hashCode;
  @override
  String toString() {
    return '$Type $Description $Amount';
  }

  @override
  Map<String, dynamic> toMap_fortable() {
    return <String, dynamic>{
      'Key': Key,
      'Document_No': Document_No,
      'Transaction_Date': Transaction_Date?.millisecondsSinceEpoch,
      'Account_No': Account_No,
      'Description': Description,
      'Amount': Amount,
      'Posted': Posted,
      'Transaction_Time': Transaction_Time?.millisecondsSinceEpoch,
      'Messages': Messages,
      'OTTN': OTTN,
      'Transaction_Location': Transaction_Location,
      'Transaction_By': Transaction_By,
      'Agent_Code': Agent_Code,
      'Loan_No': Loan_No,
      'Account_Name': Account_Name,
      'Telephone': Telephone,
      'Id_No': Id_No,
      'Constituency': Constituency,
      'Ward': Ward,
      'Type': Type,
      'sent': sent,
      'Creation_time': Creation_time?.millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> toMap() {
    return toJsonIgnoreNull(<String, dynamic>{
      'Key': Key,
      'Document_No': Document_No,
      'Transaction_Date': formattedDate.format(Transaction_Date!),
      'Account_No': Account_No,
      'Description': Description,
      'Amount': Amount,
      'Posted': Posted,
      'Transaction_Time': formattedDateTime.format(Transaction_Time!),
      'Messages': Messages,
      'OTTN': OTTN,
      'Transaction_Location': Transaction_Location,
      'Transaction_By': Transaction_By,
      'Agent_Code': Agent_Code,
      'Loan_No': Loan_No,
      'Account_Name': Account_Name,
      'Telephone': Telephone,
      'Id_No': Id_No,
      'Constituency': Constituency,
      'Ward': Ward,
      'Type': Type,
      'sent': sent,
    });
  }

  factory Trans.fromMap(Map<String, dynamic> map) {
    return Trans(
      Key: map['Key'] != null ? map['Key'] as String : null,
      Document_No:
          map['Document_No'] != null ? map['Document_No'] as String : null,
      Transaction_Date: map['Transaction_Date'] != null
          ? DateFormat("MM/dd/yyyy").parse((map['Transaction_Date'] ?? 0))
          : null,
      Account_No:
          map['Account_No'] != null ? map['Account_No'] as String : null,
      Description:
          map['Description'] != null ? map['Description'] as String : null,
      Amount: map['Amount'] != null ? (map['Amount'] as num).toDouble() : null,
      sent: map['sent'] != null ? map['sent'] as bool : null,
      Transaction_Time: map['Transaction_Time'] != "01/01/0001"
          ? DateFormat("MM/dd/yyyy HH:mm:ss")
              .parse((map['Transaction_Time'] ?? 0))
          : null,
      Messages: map['Messages'] != null ? map['Messages'] as String : null,
      OTTN: map['OTTN'] != null ? map['OTTN'] as String : null,
      Transaction_Location: map['Transaction_Location'] != null
          ? map['Transaction_Location'] as String
          : null,
      Transaction_By: map['Transaction_By'] != null
          ? map['Transaction_By'] as String
          : null,
      Agent_Code:
          map['Agent_Code'] != null ? map['Agent_Code'] as String : null,
      Loan_No: map['Loan_No'] != null ? map['Loan_No'] as String : null,
      Account_Name:
          map['Account_Name'] != null ? map['Account_Name'] as String : null,
      Telephone: map['Telephone'] != null ? map['Telephone'] as String : null,
      Id_No: map['Id_No'] != null ? map['Id_No'] as String : null,
      Constituency:
          map['Constituency'] != null ? map['Constituency'] as String : null,
      Ward: map['Ward'] != null ? map['Ward'] as String : null,
      Type: map['Type'] != null ? map['Type'] as String : null,
    );
  }
  factory Trans.fromMap_d(Map<String, dynamic> map) {
    return Trans(
      Key: map['Key'] != null ? map['Key'] as String : null,
      Document_No:
          map['Document_No'] != null ? map['Document_No'] as String : null,
      Transaction_Date: map['Transaction_Date'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['Transaction_Date'] ?? 0))
          : null,
      Account_No:
          map['Account_No'] != null ? map['Account_No'] as String : null,
      Description:
          map['Description'] != null ? map['Description'] as String : null,
      Amount: map['Amount'] != null ? map['Amount'] as double : null,
      sent: map['sent'] != null ? map['sent'] as bool : null,
      Transaction_Time: map['Transaction_Time'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['Transaction_Time'] ?? 0))
          : null,
      Messages: map['Messages'] != null ? map['Messages'] as String : null,
      OTTN: map['OTTN'] != null ? map['OTTN'] as String : null,
      Transaction_Location: map['Transaction_Location'] != null
          ? map['Transaction_Location'] as String
          : null,
      Transaction_By: map['Transaction_By'] != null
          ? map['Transaction_By'] as String
          : null,
      Agent_Code:
          map['Agent_Code'] != null ? map['Agent_Code'] as String : null,
      Loan_No: map['Loan_No'] != null ? map['Loan_No'] as String : null,
      Account_Name:
          map['Account_Name'] != null ? map['Account_Name'] as String : null,
      Telephone: map['Telephone'] != null ? map['Telephone'] as String : null,
      Id_No: map['Id_No'] != null ? map['Id_No'] as String : null,
      Constituency:
          map['Constituency'] != null ? map['Constituency'] as String : null,
      Ward: map['Ward'] != null ? map['Ward'] as String : null,
      Type: map['Type'] != null ? map['Type'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Trans.fromJson(String source) =>
      Trans.fromMap(json.decode(source) as Map<String, dynamic>);
  static const String tabletrans = 'trans';
  static const String col_Key = 'Key';
  static const String col_Document_No = 'Document_No';
  static const String col_Transaction_Date = 'Transaction_Date';
  static const String col_Account_No = 'Account_No';
  static const String col_Description = 'Description';
  static const String col_Amount = 'Amount';
  static const String col_Posted = 'Posted';
  static const String col_Transaction_Time = 'Transaction_Time';
  static const String col_Date_Posted = 'Date_Posted';
  static const String col_Time_Posted = 'Time_Posted';
  static const String col_Messages = 'Messages';
  static const String col_OTTN = 'OTTN';
  static const String col_Transaction_Location = 'Transaction_Location';
  static const String col_Transaction_By = 'Transaction_By';
  static const String col_Agent_Code = 'Agent_Code';
  static const String col_Loan_No = 'Loan_No';
  static const String col_Account_Name = 'Account_Name';
  static const String col_Telephone = 'Telephone';
  static const String col_Id_No = 'Id_No';
  static const String col_Constituency = 'Constituency';
  static const String col_Ward = 'Ward';
  static const String col_Type = 'Type';
  static const String col_sent = 'Sent';
  static const String col_Creation_time = 'Creation_time';

  static const List<String> columns = [
    col_Key,
    col_Document_No,
    col_Transaction_Date,
    col_Account_No,
    col_Description,
    col_Amount,
    col_Posted,
    col_Transaction_Time,
    col_Date_Posted,
    col_Time_Posted,
    col_Messages,
    col_OTTN,
    col_Transaction_Location,
    col_Transaction_By,
    col_Agent_Code,
    col_Loan_No,
    col_Account_Name,
    col_Telephone,
    col_Id_No,
    col_Constituency,
    col_Ward,
    col_Type,
    col_Creation_time,
    col_sent
  ];

  static const String createtable = '''create table IF NOT EXISTS $tabletrans ( 
            $col_Key	text,
            $col_Document_No	text primary key,
            $col_Transaction_Date	int,
            $col_Account_No	text,
            $col_Description	text,
            $col_Amount	float,
            $col_Posted	int,
            $col_sent	bit,
            $col_Transaction_Time	int,
            $col_Date_Posted	int,
            $col_Time_Posted	int,
            $col_Messages	text,
            $col_OTTN	text,
            $col_Transaction_Location	text,
            $col_Transaction_By	text,
            $col_Agent_Code	text,
            $col_Loan_No	text,
            $col_Account_Name	text,
            $col_Telephone	text,
            $col_Id_No	text,
            $col_Constituency	text,
            $col_Ward	text,
            $col_Type	text,
            $col_Creation_time	int


              )
              ''';

  @override
  fromMap_table(Map<String, dynamic> map) {
    // TODO: implement fromMap
    return Trans(
      Key: map['Key'] != null ? map['Key'] as String : null,
      Document_No:
          map['Document_No'] != null ? map['Document_No'] as String : null,
      Transaction_Date: map['Transaction_Date'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['Transaction_Date']))
          : null,
      Account_No:
          map['Account_No'] != null ? map['Account_No'] as String : null,
      Description:
          map['Description'] != null ? map['Description'] as String : null,
      Amount: map['Amount'] != null ? map['Amount'] as double : null,
      Posted: map['Posted'] != null ? map['Posted'] as bool : null,
      sent: map['sent'] != null ? map['sent'] as bool : null,
      Transaction_Time: map['Transaction_Time'] != null
          ? DateTime.tryParse((map['Transaction_Time'] ?? 0))
          : null,
      Messages: map['Messages'] != null ? map['Messages'] as String : null,
      OTTN: map['OTTN'] != null ? map['OTTN'] as String : null,
      Transaction_Location: map['Transaction_Location'] != null
          ? map['Transaction_Location'] as String
          : null,
      Transaction_By: map['Transaction_By'] != null
          ? map['Transaction_By'] as String
          : null,
      Agent_Code:
          map['Agent_Code'] != null ? map['Agent_Code'] as String : null,
      Loan_No: map['Loan_No'] != null ? map['Loan_No'] as String : null,
      Account_Name:
          map['Account_Name'] != null ? map['Account_Name'] as String : null,
      Telephone: map['Telephone'] != null ? map['Telephone'] as String : null,
      Id_No: map['Id_No'] != null ? map['Id_No'] as String : null,
      Constituency:
          map['Constituency'] != null ? map['Constituency'] as String : null,
      Ward: map['Ward'] != null ? map['Ward'] as String : null,
      Type: map['Type'] != null ? map['Type'] as String : null,
      Creation_time: map['Creation_time'] != null
          ? DateTime.tryParse((map['Creation_time'] ?? 0))
          : null,
    );
  }

  factory Trans.fromMap_t(Map<String, dynamic> map) {
    // TODO: implement fromMap
    return Trans(
      Key: map['Key'] != null ? map['Key'] as String : null,
      Document_No:
          map['Document_No'] != null ? map['Document_No'] as String : null,
      Transaction_Date: map['Transaction_Date'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['Transaction_Date']))
          : null,
      Account_No:
          map['Account_No'] != null ? map['Account_No'] as String : null,
      Description:
          map['Description'] != null ? map['Description'] as String : null,
      Amount: map['Amount'] != null ? map['Amount'] as double : null,
      Posted: map['Posted'] != null ? map['Posted'] == 1 : null,
      sent: map['sent'] != null ? map['sent'] as bool : null,
      Transaction_Time: map['Transaction_Time'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['Transaction_Time']))
          : null,
      Messages: map['Messages'] != null ? map['Messages'] as String : null,
      OTTN: map['OTTN'] != null ? map['OTTN'] as String : null,
      Transaction_Location: map['Transaction_Location'] != null
          ? map['Transaction_Location'] as String
          : null,
      Transaction_By: map['Transaction_By'] != null
          ? map['Transaction_By'] as String
          : null,
      Agent_Code:
          map['Agent_Code'] != null ? map['Agent_Code'] as String : null,
      Loan_No: map['Loan_No'] != null ? map['Loan_No'] as String : null,
      Account_Name:
          map['Account_Name'] != null ? map['Account_Name'] as String : null,
      Telephone: map['Telephone'] != null ? map['Telephone'] as String : null,
      Id_No: map['Id_No'] != null ? map['Id_No'] as String : null,
      Constituency:
          map['Constituency'] != null ? map['Constituency'] as String : null,
      Ward: map['Ward'] != null ? map['Ward'] as String : null,
      Type: map['Type'] != null ? map['Type'] as String : null,
      Creation_time: map['Creation_time'] != null
          ? DateTime.tryParse((map['Creation_time'] ?? 0))
          : null,
    );
  }

  Trans copyWith({
    String? Key,
    String? Document_No,
    DateTime? Transaction_Date,
    String? Account_No,
    String? Description,
    double? Amount,
    bool? Posted,
    DateTime? Transaction_Time,
    String? Messages,
    String? OTTN,
    String? Transaction_Location,
    String? Transaction_By,
    String? Agent_Code,
    String? Loan_No,
    String? Account_Name,
    String? Telephone,
    String? Id_No,
    String? Constituency,
    String? Ward,
    String? Type,
    bool? sent,
    DateTime? Creation_time,
  }) {
    return Trans(
      Key: Key ?? this.Key,
      Document_No: Document_No ?? this.Document_No,
      Transaction_Date: Transaction_Date ?? this.Transaction_Date,
      Account_No: Account_No ?? this.Account_No,
      Description: Description ?? this.Description,
      Amount: Amount ?? this.Amount,
      Posted: Posted ?? this.Posted,
      Transaction_Time: Transaction_Time ?? this.Transaction_Time,
      Messages: Messages ?? this.Messages,
      OTTN: OTTN ?? this.OTTN,
      Transaction_Location: Transaction_Location ?? this.Transaction_Location,
      Transaction_By: Transaction_By ?? this.Transaction_By,
      Agent_Code: Agent_Code ?? this.Agent_Code,
      Loan_No: Loan_No ?? this.Loan_No,
      Account_Name: Account_Name ?? this.Account_Name,
      Telephone: Telephone ?? this.Telephone,
      Id_No: Id_No ?? this.Id_No,
      Constituency: Constituency ?? this.Constituency,
      Ward: Ward ?? this.Ward,
      Type: Type ?? this.Type,
      sent: sent ?? this.sent,
      Creation_time: Creation_time ?? this.Creation_time,
    );
  }
}
