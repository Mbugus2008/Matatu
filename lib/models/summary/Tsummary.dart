// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:get/get.dart';
import 'package:t_matatu/models/summary/TsummaryDetails.dart';
import 'package:t_matatu/providers/db.dart';
import 'package:t_matatu/reports/controller.dart';

import '../Utils/util.dart';
import '../mappings.dart';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class Tsummary implements Tomaps, mapping, data {
  DateTime? Date;
  int? TotalItems;
  int? No_Of_Veh;
  double? Total;
  String? Agent;
  List<TsummaryDetails>? trans;
  Tsummary({
    this.Date,
    this.TotalItems,
    this.No_Of_Veh,
    this.Total,
    this.Agent,
    this.trans,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'Date': formattedDate.format(Date!),
      'TotalItems': TotalItems,
      'No_Of_Veh': No_Of_Veh,
      'Total': Total,
      'Agent': Agent,
    };
  }

  factory Tsummary.fromMap(Map<String, dynamic> map) {
    return Tsummary(
      Date:
          map['Date'] != null ? formattedDate.parse((map['Date'] ?? 0)) : null,
      TotalItems: map['TotalItems'] != null ? map['TotalItems'] as int : null,
      No_Of_Veh: map['No_Of_Veh'] != null ? map['No_Of_Veh'] as int : null,
      Total: map['Total'] != null ? map['Total'] as double : null,
      Agent: map['Agent'] != null ? map['Agent'] as String : null,
    );
  }
  factory Tsummary.fromMap2(Map<String, dynamic> map) {
    return Tsummary(
      Date: map['Date'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['Date'] ?? 0) as int)
          : null,
      TotalItems: map['TotalItems'] != null ? map['TotalItems'] as int : null,
      No_Of_Veh: map['No_Of_Veh'] != null ? map['No_Of_Veh'] as int : null,
      Total: map['Total'] != null ? map['Total'] as double : null,
      Agent: map['Agent'] != null ? map['Agent'] as String : null,
    );
  }
  String toJson() => json.encode(toMap());

  factory Tsummary.fromJson(String source) =>
      Tsummary.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  fromMap_table(Map<String, dynamic> map) {
    return Tsummary(
      Date: map['Date'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['Date'] ?? 0) as int)
          : null,
      TotalItems: map['TotalItems'] != null ? map['TotalItems'] as int : null,
      No_Of_Veh: map['No_Of_Veh'] != null ? map['No_Of_Veh'] as int : null,
      Total: map['Total'] != null ? map['Total'] as double : null,
      Agent: map['Agent'] != null ? map['Agent'] as String : null,
    );
  }

  @override
  toMap_fortable() {
    // TODO: implement toMap_fortable
    return toMap();
  }

  @override
  Future<List> getall() async {
    final results = await db_Provider().rawquery(
        'select Date, count(*) as TotalItems, sum(Total_Amount) as Total, Agent,( select COUNT(DISTINCT Loan_No) from trans t where t.Transaction_Date = H.Date) as No_Of_Veh   from Header h  group by Date, Agent');

    List<Tsummary> sum = results.map((map) => Tsummary.fromMap2(map)).toList();

    for (var element in sum) {
      element.trans = Get.find<ReportController>()
          .tsummarydetails
          .where((p0) => p0.Date == element.Date && p0.Agent == element.Agent)
          .toList();
    }
    //sum.sort((a, b) => b.Date!.compareTo(a.Date!));
    sum.sort((a, b) {
      if (a.Date == null && b.Date == null) return 0;
      if (a.Date == null) return 1;
      if (b.Date == null) return -1;
      return b.Date!.compareTo(a.Date!);
    });
    Get.find<ReportController>().tsummary.value = sum;

    return Get.find<ReportController>().tsummary;
  }
}
