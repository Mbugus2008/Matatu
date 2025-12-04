// ignore_for_file: public_member_api_docs, sort_constructors_first, constant_identifier_names, non_constant_identifier_names
import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:t_matatu/init.dart';
import 'package:t_matatu/models/Transaction.dart' as tmatatu;

import '../providers/db.dart';
import '../providers/dbupdates.dart' as dbu;
import 'Utils/util.dart';
import 'mappings.dart';

class Header implements Tomaps, mapping, AbsDbUpdates {
  String? Key;
  String? Receipt_No;
  DateTime? Date;
  String? Customer_Posting_Group;
  String? Account;
  String? Vehicle;
  String? Fleet;
  bool? Posted;
  bool? Reversal;
  bool? Reversed;
  bool? sent;
  int? Trans;
  double? Total_Amount;
  String? Agent;
  String? Crew;
  String? Crew2;
  String? Comments;

  List<tmatatu.Trans>? transtions;
  Header({
    this.Key,
    this.Receipt_No,
    this.Date,
    this.Customer_Posting_Group,
    this.Account,
    this.Vehicle,
    this.Fleet,
    this.Posted,
    this.Reversal,
    this.Reversed,
    this.sent,
    this.Trans,
    this.Total_Amount,
    this.Agent,
    this.Crew,
    this.Crew2,
    this.Comments,
    this.transtions,
  });
  @override
  String toString() {
    return '$Receipt_No $Account $Date $Vehicle $Fleet $Total_Amount $Agent $sent ';
  }

  Map<String, dynamic> toMap() {
    return toJsonIgnoreNull({
      'Key': Key,
      'Receipt_No': Receipt_No,
      'Customer_Posting_Group': Customer_Posting_Group,
      'Date': formattedDate.format(Date!),
      'Account': Account,
      'Comments': Comments,
      'Crew': Crew,
      'Crew2': Crew2,
      'Vehicle': Vehicle,
      'Fleet': Fleet,
      'Posted': Posted,
      'Reversal': Reversal,
      'Reversed': Reversed,
      'Trans': Trans,
      'Total_Amount': Total_Amount,
      'Agent': Agent,
      'Sent': sent,
    });
  }

  factory Header.fromMap(Map<String, dynamic> map) {
    return Header(
      Key: map['Key'] != null ? map['Key'] as String : null,
      Receipt_No:
          map['Receipt_No'] != null ? map['Receipt_No'] as String : null,
      Customer_Posting_Group: map['Customer_Posting_Group'] != null
          ? map['Customer_Posting_Group'] as String
          : null,
      Date: map['Date'] != null
          ? DateFormat("MM/dd/yyyy").parse((map['Date'] ?? 0))
          : null,
      Account: map['Account'] != null ? map['Account'] as String : null,
      Comments: map['Comments'] != null ? map['Comments'] as String : null,
      Fleet: map['Fleet'] != null ? map['Fleet'] as String : null,
      Crew: map['Crew'] != null ? map['Crew'] as String : null,
      Crew2: map['Crew2'] != null ? map['Crew2'] as String : null,
      Vehicle: map['Vehicle'] != null ? map['Vehicle'] as String : null,
      Posted: map['Posted'] != null ? map['Posted'] as bool : null,
      Reversal: map['Reversal'] != null ? map['Reversal'] as bool : null,
      Reversed: map['Reversed'] != null ? map['Reversed'] as bool : null,
      Trans: map['Trans'] != null ? map['Trans'] as int : null,
      Total_Amount: map['Total_Amount'] != null
          ? (map['Total_Amount'] as num).toDouble()
          : null,
      Agent: map['Agent'] != null ? map['Agent'] as String : null,
      sent: map['sent'] != null ? map['sent'] as bool : false,
    );
  }
  factory Header.fromMap_d2(Map<String, dynamic> map) {
    // bool posted = false, reversed = ;

    //if (map['Posted'] != null) posted = map['Posted'] == 1;

    return Header(
      Comments: map['Comments'] != null ? map['Comments'] as String : null,
      Key: map['Key'] != null ? map['Key'] as String : null,
      Receipt_No:
          map['Receipt_No'] != null ? map['Receipt_No'] as String : null,
      Customer_Posting_Group: map['Customer_Posting_Group'] != null
          ? map['Customer_Posting_Group'] as String
          : null,
      Date: map['Date'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['Date'] ?? 0) as int)
          : null,
      Account: map['Account'] != null ? map['Account'] as String : null,
      Fleet: map['Fleet'] != null ? map['Fleet'] as String : null,
      Crew: map['Crew'] != null ? map['Crew'] as String : null,
      Crew2: map['Crew2'] != null ? map['Crew2'] as String : null,
      Vehicle: map['Vehicle'] != null ? map['Vehicle'] as String : null,
      Posted: map['Posted'] != null ? map['Posted'] == 1 : null,
      Reversal: map['Reversal'] != null ? map['Reversal'] == 1 : null,
      Reversed: map['Reversed'] != null ? map['Reversed'] == 1 : null,
      Trans: map['Trans'] != null ? map['Trans'] as int : null,
      Agent: map['Agent'] != null ? map['Agent'] as String : null,
      Total_Amount: map['Total_Amount'] != null
          ? (map['Total_Amount'] as num).toDouble()
          : null,
      sent: map['Sent'] != null
          ? (map['Sent'] is int
              ? (map['Sent'] as int) == 1
              : (map['Sent'] as bool))
          : false,
    );
  }
  String toJson() => json.encode(toMap());

  factory Header.fromJson(String source) =>
      Header.fromMap(json.decode(source) as Map<String, dynamic>);

  static const String table = 'Header';
  static const String col_Key = 'Key';
  static const String col_Receipt_No = 'Receipt_No';
  static const String col_Date = 'Date';
  static const String col_Account = 'Account';
  static const String col_Vehicle = 'Vehicle';
  static const String col_Fleet = 'Fleet';
  static const String col_Posted = 'Posted';
  static const String col_Reversal = 'Reversal';
  static const String col_Reversed = 'Reversed';
  static const String col_Trans = 'Trans';
  static const String col_Sent = 'Sent';
  static const String col_Total_Amount = 'Total_Amount';
  static const String col_Agent = 'Agent';
  static const String col_Posting_Group = 'Customer_Posting_Group';
  static const String col_Crew = 'Crew';
  static const String col_Crew2 = 'Crew2';
  static const String col_Comments = 'Comments';
  static const List<String> columns = [
    col_Key,
    col_Receipt_No,
    col_Date,
    col_Account,
    col_Vehicle,
    col_Fleet,
    col_Posted,
    col_Reversal,
    col_Trans,
    col_Total_Amount,
    col_Agent,
    col_Sent,
    col_Reversed,
    col_Posting_Group,
    col_Crew,
    col_Crew2,
    col_Comments
  ];

  static const String createtable = '''create table IF NOT EXISTS $table ( 
$col_Receipt_No text primary key , 
$col_Key	text ,
$col_Date	int ,
$col_Account	text ,
$col_Crew	text ,
$col_Crew2	text ,
$col_Posted	bit ,
$col_Reversal	bit ,
$col_Reversed	bit ,
$col_Sent	bit ,
$col_Total_Amount	float ,
$col_Trans	int ,
$col_Vehicle	text ,
$col_Fleet	text ,
$col_Posting_Group	text ,
$col_Agent	text ,
$col_Comments	text 
 )
''';

  @override
  fromMap_table(Map<String, dynamic> map) {
    // TODO: implement fromMap
    return Header(
      Key: map['Key'] != null ? map['Key'] as String : null,
      Receipt_No:
          map['Receipt_No'] != null ? map['Receipt_No'] as String : null,
      Customer_Posting_Group: map['Customer_Posting_Group'] != null
          ? map['Customer_Posting_Group'] as String
          : null,
      Date: map['Date'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['Date'] ?? 0) as int)
          : null,
      Account: map['Account'] != null ? map['Account'] as String : null,
      Fleet: map['Fleet'] != null ? map['Fleet'] as String : null,
      Crew: map['Crew'] != null ? map['Crew'] as String : null,
      Crew2: map['Crew2'] != null ? map['Crew2'] as String : null,
      Vehicle: map['Vehicle'] != null ? map['Vehicle'] as String : null,
      Posted: map['Posted'] != null ? map['Posted'] as bool : null,
      Reversal: map['Reversal'] != null ? map['Reversal'] as bool : null,
      Reversed: map['Reversed'] != null ? map['Reversed'] as bool : null,
      Trans: map['Trans'] != null ? map['Trans'] as int : null,
      Total_Amount:
          map['Total_Amount'] != null ? map['Total_Amount'] as double : null,
      Agent: map['Agent'] != null ? map['Agent'] as String : null,
      Comments: map['Comments'] != null ? map['Comments'] as String : null,
      sent: map['sent'] != null ? map['sent'] as bool : false,
    );
  }

  @override
  toMap_fortable() {
    // TODO: implement toMap_fortable
    return <String, dynamic>{
      'Key': Key,
      'Receipt_No': Receipt_No,
      'Customer_Posting_Group': Customer_Posting_Group,
      'Date': Date?.millisecondsSinceEpoch,
      'Account': Account,
      'Crew': Crew,
      'Crew2': Crew2,
      'Vehicle': Vehicle,
      'Fleet': Fleet,
      'Posted': Posted,
      'Reversal': Reversal,
      'Reversed': Reversed,
      'Trans': Trans,
      'Total_Amount': Total_Amount,
      'Agent': Agent,
      'Comments': Comments,
      'Sent': sent,
    };
  }

  @override
  List<dbu.DbUpdate>? updates() {
    return dbu.getDbUpdatesForTable(table);
  }

  Header copyWith({
    String? Key,
    String? Receipt_No,
    DateTime? Date,
    String? Account,
    String? Vehicle,
    String? Fleet,
    bool? Posted,
    bool? Reversal,
    bool? Reversed,
    bool? sent,
    int? Trans,
    double? Total_Amount,
    String? Agent,
    String? Customer_Posting_Group,
    String? Crew,
    String? Crew2,
    List<tmatatu.Trans>? transtions,
  }) {
    return Header(
      Key: Key ?? this.Key,
      Receipt_No: Receipt_No ?? this.Receipt_No,
      Date: Date ?? this.Date,
      Account: Account ?? this.Account,
      Fleet: Fleet ?? this.Fleet,
      Vehicle: Vehicle ?? this.Vehicle,
      Posted: Posted ?? this.Posted,
      Reversal: Reversal ?? this.Reversal,
      Reversed: Reversed ?? this.Reversed,
      sent: sent ?? this.sent,
      Trans: Trans ?? this.Trans,
      Total_Amount: Total_Amount ?? this.Total_Amount,
      Agent: Agent ?? this.Agent,
      Customer_Posting_Group:
          Customer_Posting_Group ?? this.Customer_Posting_Group,
      Crew: Crew ?? this.Crew,
      Crew2: Crew2 ?? this.Crew2,
      transtions: transtions ?? this.transtions,
      Comments: Comments ?? this.Comments,
    );
  }
}
