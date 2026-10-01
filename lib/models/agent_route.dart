// ignore_for_file: public_member_api_docs, sort_constructors_first
// ignore_for_file: non_constant_identifier_names

import 'package:t_matatu/models/mappings.dart';
import 'package:t_matatu/models/route.dart';
import 'package:t_matatu/network/Apis.dart';
import 'package:t_matatu/network/results/results.dart';
import 'package:t_matatu/providers/db.dart';

/// Agent → Route assignment from BC's AgentRoutes page: which routes an
/// agent is allowed to pick when starting a trip.
class AgentRouteModel extends Tomaps implements mapping {
  String? Key;
  String? Agent;
  String? Route;
  bool sent = false;

  AgentRouteModel({this.Key, this.Agent, this.Route, this.sent = false});

  @override
  Map<String, dynamic> toMap() => <String, dynamic>{
        'Key': Key,
        'Agent': Agent,
        'Route': Route,
      };

  static AgentRouteModel fromMap(Map<String, dynamic> map) => AgentRouteModel(
        Key: map['Key'] as String?,
        Agent: map['Agent'] as String?,
        Route: map['Route'] as String?,
      );

  @override
  AgentRouteModel fromMap_table(Map<String, dynamic> map) =>
      AgentRouteModel.fromMap_db(map);

  @override
  Map<String, dynamic> toMap_fortable() => <String, dynamic>{
        'Key': Key ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'Agent': Agent,
        'Route': Route,
        'sent': sent ? 1 : 0,
      };

  // ─── Database ───
  static const String table = 'agent_routes';
  static const String col_Key = 'Key';
  static const String col_Agent = 'Agent';
  static const String col_Route = 'Route';
  static const String col_sent = 'sent';

  static const List<String> columns = [
    col_Key,
    col_Agent,
    col_Route,
    col_sent,
  ];

  static const String createtable = '''
    CREATE TABLE IF NOT EXISTS $table (
      $col_Key TEXT PRIMARY KEY,
      $col_Agent TEXT,
      $col_Route TEXT,
      $col_sent INTEGER DEFAULT 0
    )
  ''';

  factory AgentRouteModel.fromMap_db(Map<String, dynamic> map) {
    final r = AgentRouteModel.fromMap(map);
    r.Key = map[col_Key] as String?;
    r.sent = (map[col_sent] as int?) == 1;
    return r;
  }
}

/// API and local DB service for AgentRoutes.
class AgentRouteService {
  final ApiClient _api = ApiClient();

  /// Fetch agent-route assignments from the API.
  Future<List<AgentRouteModel>> fetchFromAPI() async {
    try {
      final response = await _api.postdata('agentroutes', '{}');
      final result = Results<AgentRouteModel>.fromJson(
          response.body, AgentRouteModel.fromMap);
      if (result.Code == 0 && result.Contents != null) {
        return result.Contents!;
      }
    } catch (_) {}
    return [];
  }

  /// Load agent-route assignments from the local DB.
  Future<List<AgentRouteModel>> loadFromLocalDB() async {
    try {
      final db = db_Provider();
      final rows = await db.getdata(AgentRouteModel.table,
          AgentRouteModel.columns);
      return rows.map((m) => AgentRouteModel.fromMap_db(m)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Pulls the assignments from BC and merges them locally. Assignments that
  /// no longer exist in BC are removed, so the trip route picker can never
  /// offer a route the agent has lost access to.
  Future<void> syncAgentRoutes() async {
    final apiRoutes = await fetchFromAPI();
    if (apiRoutes.isEmpty) return;

    final db = db_Provider();
    for (final assignment in apiRoutes) {
      assignment.sent = true;
      await db.insert(AgentRouteModel.table, assignment);
    }

    final serverKeys =
        apiRoutes.map((r) => r.Key).whereType<String>().toSet();
    final local = await db.getdata(AgentRouteModel.table,
        AgentRouteModel.columns, '${AgentRouteModel.col_sent} = 1');
    for (final row in local.map(AgentRouteModel.fromMap_db)) {
      final key = row.Key;
      if (key == null || key.isEmpty) continue;
      if (!serverKeys.contains(key)) {
        await db.deletedata(
            AgentRouteModel.table, '${AgentRouteModel.col_Key} = ?', [key]);
      }
    }
  }

  /// Route codes assigned to [agentCode]. An empty set means the agent has no
  /// assignments on record (callers decide whether to fall back to all routes).
  Future<Set<String>> routeCodesForAgent(String? agentCode) async {
    final target = (agentCode ?? '').trim().toUpperCase();
    if (target.isEmpty) return <String>{};

    final rows = await loadFromLocalDB();
    return rows
        .where((r) => (r.Agent ?? '').trim().toUpperCase() == target)
        .map((r) => (r.Route ?? '').trim())
        .where((code) => code.isNotEmpty)
        .toSet();
  }

  /// Routes an agent may pick for a trip: everything when no assignments are
  /// on record yet, otherwise only the assigned route codes.
  static List<RouteModel> allowedRoutes(
          List<RouteModel> routes, Set<String> assignedCodes) =>
      assignedCodes.isEmpty
          ? routes
          : routes
              .where((r) => assignedCodes.contains((r.Code ?? '').trim()))
              .toList();
}
