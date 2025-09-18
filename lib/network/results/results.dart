// ignore_for_file: public_member_api_docs, sort_constructors_first, non_constant_identifier_names
import 'dart:convert';

import 'package:t_matatu/models/mappings.dart';

class Results<T extends Tomaps> {
  int? Code = 0;
  String? Desc = "Successful";
  List<T>? Contents;
  Results({
    int? code,
    String? desc,
    this.Code,
    this.Desc,
    this.Contents,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'Code': Code,
      'Desc': Desc,
      'Contents': Contents?.map((x) => x.toMap()).toList(),
    };
  }

  factory Results.fromMap(
      Map<String, dynamic> map, T Function(Map<String, dynamic>) createT) {
    print("map: $map");
    Results<T> results = Results(
      Code: map['Code'] != null ? map['Code'] as int : null,
      Desc: map['Desc'] != null ? map['Desc'] as String : null,
      Contents: map['Contents'] != null
          ? (map['Contents'] as List<dynamic>)
              .map((x) => createT(x as Map<String, dynamic>))
              .toList()
          : null,
    );
    print("results: ${results.Contents}");
    return results; 
    // return Results(
    //   Code: map['Code'] != null ? map['Code'] as int : null,
    //   Desc: map['Desc'] != null ? map['Desc'] as String : null,
    //   Contents: map['Contents'] != null
    //       ? (map['Contents'] as List<dynamic>)
    //           .map((x) => createT(x as Map<String, dynamic>))
    //           .toList()
    //       : null,
    // );
  }
  String toJson() => json.encode(toMap());
  factory Results.fromJson(
          String source, T Function(Map<String, dynamic>) createT) {
    print("source: $source");
    return Results.fromMap(json.decode(source) as Map<String, dynamic>, createT);
  }
}

class Results2<T extends Tomaps> {
  int? Code = 0;
  String? Desc = "Successful";
  T? Contents;
  Results2({
    int? code,
    String? desc,
    this.Code,
    this.Desc,
    this.Contents,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'Code': Code,
      'Desc': Desc,
      'Contents': Contents?.toMap()
    };
  }

  factory Results2.fromMap(
      Map<String, dynamic> map, T Function(Map<String, dynamic>) createT) {
    return Results2(
        Code: map['Code'] != null ? map['Code'] as int : null,
        Desc: map['Desc'] != null ? map['Desc'] as String : null,
        Contents: map['Contents'] != null
            ? createT(map['Contents'] as Map<String, dynamic>)
            : null);
    // Contents: map['Contents'] != null ? map['Contents'] as String : null);
  }

  String toJson() => json.encode(toMap());

  factory Results2.fromJson(
          String source, T Function(Map<String, dynamic>) createT) =>
      Results2.fromMap(json.decode(source) as Map<String, dynamic>, createT);
}
