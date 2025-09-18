// ignore_for_file: public_member_api_docs, sort_constructors_first, non_constant_identifier_names
import 'dart:convert';

import 'package:get/get.dart';

import '../../providers/db.dart';
import '../../reports/controller.dart';
import '../mappings.dart';

class TsummaryDetails implements Tomaps, mapping, data {
  String? Agent;
  DateTime? Date;
  String? Description;
  double? Total;
  int? TotalItems;

  TsummaryDetails({
    this.Agent,
    this.Date,
    this.Description,
    this.Total,
    this.TotalItems,
  });

  @override
  fromMap_table(Map<String, dynamic> map) {
    // TODO: implement fromMap_table
    throw UnimplementedError();
  }

  @override
  Future<List> getall() async {
    final results = await db_Provider().rawquery(
        'select Transaction_Date as Date, (select Name from TranTypes tt where tt.Code = t.Type) as Description, sum(Amount) as Total, count(*) as TotalItems,Agent_Code as Agent from trans t group by   Transaction_Date,Type,Agent_Code');
    Get.find<ReportController>().tsummarydetails.value =
        results.map((map) => TsummaryDetails.fromMap(map)).toList();
    return Get.find<ReportController>().tsummarydetails;
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'Date': Date?.millisecondsSinceEpoch,
      'Description': Description,
      'Agent': Agent,
      'Total': Total,
      'TotalItems': TotalItems,
    };
  }

  @override
  toMap_fortable() {
    // TODO: implement toMap_fortable
    throw UnimplementedError();
  }

  factory TsummaryDetails.fromMap(Map<String, dynamic> map) {
    return TsummaryDetails(
      Date: map['Date'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['Date'] ?? 0) as int)
          : null,
      Description:
          map['Description'] != null ? map['Description'] as String : null,
      Agent: map['Agent'] != null ? map['Agent'] as String : null,
      Total: map['Total'] != null ? map['Total'] as double : null,
      TotalItems: map['TotalItems'] != null ? map['TotalItems'] as int : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory TsummaryDetails.fromJson(String source) =>
      TsummaryDetails.fromMap(json.decode(source) as Map<String, dynamic>);
}
