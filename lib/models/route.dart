// ignore_for_file: public_member_api_docs, sort_constructors_first
// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:t_matatu/models/mappings.dart';
import 'package:t_matatu/network/Apis.dart';
import 'package:t_matatu/network/results/results.dart';
import 'package:t_matatu/providers/db.dart';

/// Route model — From/To routes used by weigh bridge trips.
class RouteModel extends Tomaps implements mapping {
  String? Key;
  String? Code;
  String? Description;
  bool sent = false;

  RouteModel({this.Key, this.Code, this.Description, this.sent = false});

  @override
  Map<String, dynamic> toMap() => <String, dynamic>{
        'Key': Key,
        'Code': Code,
        'Description': Description,
      };

  static RouteModel fromMap(Map<String, dynamic> map) => RouteModel(
        Key: map['Key'] as String?,
        Code: map['Code'] as String?,
        Description: map['Description'] as String?,
      );

  @override
  RouteModel fromMap_table(Map<String, dynamic> map) =>
      RouteModel.fromMap_db(map);

  @override
  Map<String, dynamic> toMap_fortable() => <String, dynamic>{
        'Key': Key ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'Code': Code,
        'Description': Description,
        'sent': sent ? 1 : 0,
      };

  // ─── Database ───
  static const String table = 'routes';
  static const String col_Key = 'Key';
  static const String col_Code = 'Code';
  static const String col_Description = 'Description';
  static const String col_sent = 'sent';

  static const List<String> columns = [
    col_Key,
    col_Code,
    col_Description,
    col_sent,
  ];

  static const String createtable = '''
    CREATE TABLE IF NOT EXISTS $table (
      $col_Key TEXT PRIMARY KEY,
      $col_Code TEXT,
      $col_Description TEXT,
      $col_sent INTEGER DEFAULT 0
    )
  ''';

  String toJson() => json.encode(toMap());
  factory RouteModel.fromJson(String source) =>
      RouteModel.fromMap(json.decode(source));

  factory RouteModel.fromMap_db(Map<String, dynamic> map) {
    final r = RouteModel.fromMap(map);
    r.Key = map[col_Key] as String?;
    r.sent = (map[col_sent] as int?) == 1;
    return r;
  }
}

/// API and local DB service for Routes.
class RouteService {
  final ApiClient _api = ApiClient();

  /// Fetch routes from API
  Future<List<RouteModel>> fetchFromAPI() async {
    try {
      final response = await _api.postdata('Matatu/routes', '{}');
      final result =
          Results<RouteModel>.fromJson(response.body, RouteModel.fromMap);
      if (result.Code == 0 && result.Contents != null) {
        return result.Contents!;
      }
    } catch (_) {}
    return [];
  }

  /// Load routes from local DB
  Future<List<RouteModel>> loadFromLocalDB() async {
    try {
      final db = db_Provider();
      final rows = await db.getdata(RouteModel.table, RouteModel.columns);
      return rows.map((m) => RouteModel.fromMap_db(m)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Sync routes: fetch from API, save to local DB
  Future<void> syncRoutes() async {
    final apiRoutes = await fetchFromAPI();
    if (apiRoutes.isEmpty) return;

    final db = db_Provider();
    for (final route in apiRoutes) {
      route.sent = true;
      await db.insert(RouteModel.table, route);
    }
  }
}
