// ignore_for_file: non_constant_identifier_names, camel_case_types, constant_identifier_names

import 'dart:convert';

import 'package:get/get.dart';
import 'package:t_matatu/controllers/vehicles/vehicles.dart';
import 'package:t_matatu/models/mappings.dart';
import 'package:t_matatu/models/member.dart';
import 'package:t_matatu/providers/db.dart';
import 'package:t_matatu/models/Transaction.dart' as tmatatu;
import '../../network/Apis.dart';
import '../../network/request.dart';
import '../../network/results/results.dart';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class Vehicles implements mapping, Tomaps, AbsDbUpdates {
  String? Key;
  String? Vehicle_Number;
  vehicle_type? Vehicle_Type;
  double? Daily_Contribution;
  String? Start_Date;
  String? Code;
  String? Id_Number;
  double? Penalty;
  double? Parking;
  String? Fleet_No;
  double? Offload = 0;
  double? Management = 0;
  double get total => (Offload ?? 0) + (Management ?? 0);
  Member? Driver;
  Member? Conductor;
  double? Mpesa;
  double? Cash;
  List<tmatatu.Trans>? transactions;

  // Member? get Driver =>
  //     Get.find<MemberController>().Crews.firstWhereOrNull((element) =>
  //         element.Vehicle == Vehicle_Number &&
  //         element.Crew_Type == Crew_type.Driver);
  // Member? get Conductor =>
  //     Get.find<MemberController>().Crews.firstWhereOrNull((element) =>
  //         element.Vehicle == Vehicle_Number &&
  //         element.Crew_Type == Crew_type.Conductor);

  Vehicles({
    this.Key,
    this.Vehicle_Number,
    this.Vehicle_Type,
    this.Daily_Contribution,
    this.Start_Date,
    this.Code,
    this.Id_Number,
    this.Penalty,
    this.Parking,
    this.Mpesa,
    this.Cash,
    this.Fleet_No,
    this.Offload,
    this.Management,
    this.transactions,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'Key': Key,
      'Vehicle_Number': Vehicle_Number,
      'Vehicle_Type': Vehicle_Type?.index,
      'Daily_Contribution': Daily_Contribution,
      'Start_Date': Start_Date,
      'Code': Code,
      'Id_Number': Id_Number,
      'Penalty': Penalty,
      'Parking': Parking,
      'Fleet_No': Fleet_No,
      'Offload': Offload,
      'Management': Management,
      'Mpesa': Mpesa,
      'Cash': Cash,
    };
  }

  factory Vehicles.fromMap(Map<String, dynamic> map) {
    return Vehicles(
      Key: map['Key'] != null ? map['Key'] as String : null,
      Vehicle_Number: map['Vehicle_Number'] != null
          ? map['Vehicle_Number'] as String
          : null,
      Vehicle_Type: map['Vehicle_Type'] != null
          ? vehicle_type.values[(map['Vehicle_Type']) as int]
          : null,
      Daily_Contribution: map['Daily_Contribution'] != null
          ? (map['Daily_Contribution'] as num).toDouble()
          : null,
      Start_Date:
          map['Start_Date'] != null ? map['Start_Date'] as String : null,
      Code: map['Code'] != null ? map['Code'] as String : null,
      Id_Number: map['Id_Number'] != null ? map['Id_Number'] as String : null,
      Penalty: map['Penalty'] != null ? map['Penalty'] as double : null,
      Parking: map['Parking'] != null ? map['Parking'] as double : null,
      Fleet_No: map['Fleet_No'] != null ? map['Fleet_No'] as String : null,
      Offload: map['Offload'] != null ? map['Offload'] as double : null,
      Management:
          map['Management'] != null ? map['Management'] as double : null,
      Mpesa: map['Mpesa'] != null ? map['Mpesa'] as double : null,
      Cash: map['Cash'] != null ? map['Cash'] as double : null,
    );
  }
  @override
  String toString() {
    return '$Code $Vehicle_Number $Fleet_No $Vehicle_Type ';
  }

  String toJson() => json.encode(toMap());

  factory Vehicles.fromJson(String source) =>
      Vehicles.fromMap(json.decode(source) as Map<String, dynamic>);

  static const String table = 'vehicles';
  static const String col_Vehicle_Number = 'Vehicle_Number';
  static const String col_vehicle_type = 'Vehicle_Type';
  static const String col_Daily_Contribution = 'Daily_Contribution';
  static const String col_Start_Date = 'Start_Date';
  static const String col_Code = 'Code';
  static const String col_Id_Number = 'Id_Number';
  static const String col_Penalty = 'Penalty';
  static const String col_Parking = 'Parking';
  static const String col_Fleet_No = 'Fleet_No';
  static const List<String> columns = [
    col_Vehicle_Number,
    col_vehicle_type,
    col_Daily_Contribution,
    col_Start_Date,
    col_Code,
    col_Id_Number,
    col_Fleet_No
  ];
  static const String createtable = '''create table IF NOT EXISTS $table ( 
$col_Vehicle_Number text primary key , 
$col_vehicle_type	int ,
$col_Daily_Contribution	float ,
$col_Start_Date	int ,
$col_Code	text ,
$col_Fleet_No	text ,
$col_Id_Number	text 
 )
''';
  @override
  List<DbUpdate>? updates() {
    List<DbUpdate> update = [];

    update.add(DbUpdate(version: 3, updates: []));

    return update;
  }

  @override
  fromMap_table(Map<String, dynamic> map) {
    return Vehicles(
      Vehicle_Number: map['Vehicle_Number'] != null
          ? map['Vehicle_Number'] as String
          : null,
      Vehicle_Type: map['Vehicle_Type'] != null
          ? vehicle_type.values[(map['Vehicle_Type']) as int]
          : null,
      Daily_Contribution: map['Daily_Contribution'] != null
          ? (map['Daily_Contribution'] as num).toDouble()
          : null,
      Offload: map['Offload'] != null ? map['Offload'] as double : null,
      Management:
          map['Management'] != null ? map['Management'] as double : null,
      Start_Date:
          map['Start_Date'] != null ? map['Start_Date'] as String : null,
      Code: map['Code'] != null ? map['Code'] as String : null,
      Id_Number: map['Id_Number'] != null ? map['Id_Number'] as String : null,
      Fleet_No: map['Fleet_No'] != null ? map['Fleet_No'] as String : null,
    );
  }

  @override
  toMap_fortable() {
    return <String, dynamic>{
      'Vehicle_Number': Vehicle_Number,
      'vehicle_type': Vehicle_Type?.index,
      'Daily_Contribution': Daily_Contribution,
      'Start_Date': Start_Date,
      'Code': Code,
      'Id_Number': Id_Number,
      'Fleet_No': Fleet_No,
    };
  }

  Future<List<Vehicles>> Daily_Contributions(DateTime date) async {
    var request = Request(date: date);
    ApiClient().postdata("Dailytrans", request.toJson()).then((r) async {
      if (r.statusCode == 200) {
        Results<Vehicles> results =
            Results<Vehicles>.fromJson(r.body, Vehicles.fromMap);
        if (results.Code == 0) {
          if (results.Contents != null) {
            Get.find<VehiclesController>().vehdailycollections.value =
                (results.Contents as List<Vehicles>)
                  ..sort((a, b) => a.Fleet_No!.compareTo(b.Fleet_No as String));
            Get.find<VehiclesController>().vehdailycollectionsf.value =
                (results.Contents as List<Vehicles>)
                  ..sort((a, b) => a.Fleet_No!.compareTo(b.Fleet_No as String));
            return results.Contents as List<Vehicles>;
          }
        }
      }
    });
    return [];
  }Future<List<tmatatu.Trans>> Daily_Veh_Contributions(DateTime date,String? vehicle) async {
    var request = Request(date: date,vehicle: vehicle );
    ApiClient().postdata("getvehicletrans", request.toJson()).then((r) async {
      if (r.statusCode == 200) {
        Results<tmatatu.Trans> results =
        Results<tmatatu.Trans>.fromJson(r.body, tmatatu.Trans.fromMap);
        if (results.Code == 0) {
          if (results.Contents != null) {
            Get.find<VehiclesController>().vehcollections.value =
            (results.Contents as List<tmatatu.Trans>)
              ..sort((a, b) => a.Transaction_Time!.compareTo(b.Transaction_Time as DateTime));

            return results.Contents as List<tmatatu.Trans>;
          }
        }
      }
    });
    return [];
  }





  Future<void> getvehicles() async {
    bool hasdata = true;
    String? bookmark;
    int? size = 50;
    var request = Request(body: null, bookmark: bookmark, size: size);
    while (hasdata) {
      await ApiClient().postdata("vehicles", request.toJson()).then((r) async {
        if (r.statusCode == 200) {
          Results<Vehicles> results =
              Results<Vehicles>.fromJson(r.body, Vehicles.fromMap);
          if (results.Code == 0) {
            if (results.Contents != null) {
              hasdata = results.Contents!.isNotEmpty;
              if (results.Contents!.isNotEmpty) {
                Get.find<db_Provider>().batchinsert(
                    Vehicles.table, results.Contents as List<Vehicles>);
                bookmark = results.Contents!.last.Key;
                request = Request(body: null, bookmark: bookmark, size: size);
              }
              // for (Vehicles element in results.Contents as List<Vehicles>) {
              // db.insert(Vehicles.table, element);
              //}
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
        //The operation has timed out
      });
    }
    //db_Provider().transactionprocess();
  }
}

enum vehicle_type {
  _blank_,

  /// <remarks/>
  _x0031_4_Seater,

  /// <remarks/>
  _x0033_3_Seater,

  /// <remarks/>
  _x0032_5_Seater,

  /// <remarks/>
  _x0032_9_Seater,

  /// <remarks/>
  _41_Seater,

  /// <remarks/>
  _26_Seater,

  /// <remarks/>
  _37_Seater,

  /// <remarks/>
  _x0035_1_Seater,

  /// <remarks/>
  _x0033_4_Seater,

  /// <remarks/>
  _x0033_8_Seater,

  /// <remarks/>
  _x0034_0_Seater,

  /// <remarks/>
  _x0034_6_Seater,

  /// <remarks/>
  _x0036_0_Seater,

  /// <remarks/>
  _x0033_5_Seater,

  /// <remarks/>
  _x0033_6_Seater,

  /// <remarks/>
  _x0033_9_Seater,
}

class vehicle_type_desc {
  static const Map<vehicle_type, String> desc = {
    vehicle_type._blank_: '',
    vehicle_type._x0031_4_Seater: '14 Seater',
    vehicle_type._x0033_3_Seater: '33 Seater',
    vehicle_type._x0032_5_Seater: '25 Seater',
    vehicle_type._x0032_9_Seater: '29 Seater',
    vehicle_type._41_Seater: '41 Seater',
    vehicle_type._26_Seater: '26 Seater',
    vehicle_type._37_Seater: '37 Seater',
    vehicle_type._x0035_1_Seater: '51 Seater',
    vehicle_type._x0033_4_Seater: '34 Seater',
    vehicle_type._x0033_8_Seater: '38 Seater',
    vehicle_type._x0034_0_Seater: '40 Seater',
    vehicle_type._x0034_6_Seater: '46 Seater',
    vehicle_type._x0036_0_Seater: '60 Seater',
    vehicle_type._x0033_5_Seater: '35 Seater',
    vehicle_type._x0033_6_Seater: '36 Seater',
    vehicle_type._x0033_9_Seater: '39 Seater',
  };
}
