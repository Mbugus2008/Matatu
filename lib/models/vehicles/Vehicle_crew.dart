import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:t_matatu/models/Utils/util.dart';
import 'package:t_matatu/models/mappings.dart';

class Vehicle_Crew implements mapping, Tomaps {
  String? Key;
  String? Vehicle;
  String? Crew;
  Crew_type? Crew_Type;
  DateTime? Date_Created;
  String? Created_By;
  String? Crew_Name;
  String? Fleet_No;
  Vehicle_Crew({
    this.Key,
    this.Vehicle,
    this.Crew,
    this.Crew_Type,
    this.Date_Created,
    this.Created_By,
    this.Crew_Name,
    this.Fleet_No,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'Key': Key,
      'Vehicle': Vehicle,
      'Crew': Crew,
      'Crew_Type': Crew_Type?.index,
      'Date_Created': Date_Created ?? formattedDate.format(Date_Created!),
      'Created_By': Created_By,
      'Crew_Name': Crew_Name,
      'Fleet_No': Fleet_No,
    };
  }

  factory Vehicle_Crew.fromMap(Map<String, dynamic> map) {
    return Vehicle_Crew(
      Key: map['Key'] != null ? map['Key'] as String : null,
      Vehicle: map['Vehicle'] != null ? map['Vehicle'] as String : null,
      Crew: map['Crew'] != null ? map['Crew'] as String : null,
      Crew_Type: map['Crew_Type'] != null
          ? Crew_type.values[(map['Crew_Type'] as int)]
          : null,
      Date_Created: map['Date_Created'] != null
          ? DateFormat("dd/MM/yyyy").parse((map['Date_Created'] ?? 0))
          : null,
      Created_By:
          map['Created_By'] != null ? map['Created_By'] as String : null,
      Crew_Name: map['Crew_Name'] != null ? map['Crew_Name'] as String : null,
      Fleet_No: map['Fleet_No'] != null ? map['Fleet_No'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Vehicle_Crew.fromJson(String source) =>
      Vehicle_Crew.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  fromMap_table(Map<String, dynamic> map) {
    return Vehicle_Crew.fromMap_db(map);
  }

  factory Vehicle_Crew.fromMap_db(Map<String, dynamic> map) {
    var d = Vehicle_Crew.fromMap(map);
    d.Date_Created = map['Date_Created'] != null
        ? DateTime.fromMillisecondsSinceEpoch((map['Date_Created'] ?? 0) as int)
        : null;
    return d;
  }

  @override
  toMap_fortable() {
    var d = toMap();
    d['Date_Created'] = Date_Created?.millisecondsSinceEpoch;
    return d;
  }

//Database
  static const String table = 'vehiclecrew';
  static const String col_Key = "Key";
  static const String col_Vehicle = "Vehicle";
  static const String col_Crew = "Crew";
  static const String col_Crew_Type = "Crew_Type";
  static const String col_Date_Created = "Date_Created";
  static const String col_Created_By = "Created_By";
  static const String col_Crew_Name = "Crew_Name";
  static const String col_Fleet_No = "Fleet_No";

  static const List<String> columns = [
    col_Vehicle,
    col_Crew,
    col_Crew_Type,
    col_Date_Created,
    col_Created_By,
    col_Crew_Name,
    col_Fleet_No
  ];
  static const String createtable = '''create table IF NOT EXISTS $table ( 
$col_Vehicle text , 
$col_Crew	text ,
$col_Crew_Type	text ,
$col_Date_Created	int ,
$col_Created_By	text ,
$col_Crew_Name	text ,
$col_Fleet_No	text ,
PRIMARY KEY ($col_Vehicle, $col_Crew,$col_Date_Created)
 )
''';
}

enum Crew_type {
  /// <remarks/>
  _blank_,

  /// <remarks/>
  Driver,

  /// <remarks/>
  Conductor,
}
