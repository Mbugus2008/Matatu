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
      final response = await _api.postdata('routes', '{}');
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

  /// Pulls the route list from BC and merges it locally. Routes that are no
  /// longer in BC are removed, because NAV validates trip From/To against its
  /// own route codes — a stale local code would make the trip fail to sync.
  Future<void> syncRoutes() async {
    final apiRoutes = await fetchFromAPI();
    if (apiRoutes.isEmpty) return;

    final db = db_Provider();
    for (final route in apiRoutes) {
      route.sent = true;
      await db.insert(RouteModel.table, route);
    }

    final serverKeys =
        apiRoutes.map((r) => r.Key).whereType<String>().toSet();
    final local = await db.getdata(RouteModel.table, RouteModel.columns,
        '${RouteModel.col_sent} = 1');
    for (final row in local.map(RouteModel.fromMap_db)) {
      final key = row.Key;
      if (key == null || key.isEmpty) continue;
      if (!serverKeys.contains(key)) {
        await db.deletedata(
            RouteModel.table, '${RouteModel.col_Key} = ?', [key]);
      }
    }
  }

  // ─── Creating routes ───

  /// Short code for a route named on the device. BC's own codes are letters
  /// and digits only (GPO, KENCOM, AMBASSANDER), so match that shape rather
  /// than inventing a different convention.
  static String codeFromDescription(String description) {
    final code = description.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (code.isEmpty) {
      return 'ROUTE${DateTime.now().millisecondsSinceEpoch % 100000}';
    }
    return code.length <= 20 ? code : code.substring(0, 20);
  }

  /// Creates a route from [description]: stored locally straight away, then
  /// pushed to Business Central. The local row survives if the push fails, so
  /// a route captured offline is not lost and goes up on the next sync.
  Future<RouteModel> createRoute(String description) async {
    final route = RouteModel(
      Key: DateTime.now().millisecondsSinceEpoch.toString(),
      Code: codeFromDescription(description),
      Description: description.trim(),
      sent: false,
    );

    await db_Provider().insert(RouteModel.table, route);
    await postRoute(route);
    return route;
  }

  /// Pushes one route to BC and adopts whatever Key/Code comes back.
  Future<bool> postRoute(RouteModel route) async {
    try {
      final response = await _api.postdata('addroute', route.toJson());
      final result =
          Results<RouteModel>.fromJson(response.body, RouteModel.fromMap);
      if (result.Code != 0 ||
          result.Contents == null ||
          result.Contents!.isEmpty) {
        return false;
      }

      final server = result.Contents!.first;
      final db = db_Provider();

      // BC may hand back its own key: move the row instead of leaving a twin.
      if (server.Key != null && server.Key != route.Key) {
        if (route.Key != null) {
          await db.deletedata(
              RouteModel.table, '${RouteModel.col_Key} = ?', [route.Key!]);
        }
        route.Key = server.Key;
      }

      route.Code = server.Code ?? route.Code;
      route.Description = server.Description ?? route.Description;
      route.sent = true;
      await db.insert(RouteModel.table, route);
      return true;
    } catch (_) {
      // Left unsent - retried by syncPendingRoutes().
      return false;
    }
  }

  /// Pushes every route captured on the device that BC has not accepted yet.
  Future<int> syncPendingRoutes() async {
    var synced = 0;
    try {
      final rows = await db_Provider().getdata(
          RouteModel.table, RouteModel.columns, '${RouteModel.col_sent} = 0');
      for (final route in rows.map(RouteModel.fromMap_db)) {
        if (await postRoute(route)) synced++;
      }
    } catch (_) {
      // Offline or DB not ready: they stay pending.
    }
    return synced;
  }
}
