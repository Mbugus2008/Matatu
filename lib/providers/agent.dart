import 'package:t_matatu/models/agents.dart';
import 'package:t_matatu/providers/db.dart';

class AgentProvider extends db_Provider {
  // Future<Agent> insert(Agent data) async {
  //   await db!.insert(Agent.tableagents, data.toMap());
  //   return data;
  // }

  // Future<List<Agent>?> getalltrans() async {
  //   final List<Map<String, dynamic>> maps =
  //       await db!.query(Agent.tableagents, columns: Agent.columns);
  //   if (maps.isNotEmpty) {
  //     return maps.map((row) {
  //       return Agent.fromMap(row);
  //     }).toList();
  //   }
  //   return Future.value(null);
  // }

  // Future<Agent?> gettrans(String id) async {
  //   List<Map<String, Object?>>? maps = await db!.query(Agent.tableagents,
  //       columns: Agent.columns,
  //       where: '$Agent.col_Agent_Code = ?',
  //       whereArgs: [id]);
  //   if (maps.isNotEmpty) {
  //     return Agent.fromMap(maps.first);
  //   }

  //   return Future.value(null);
  // }

  // Future<int> delete(int id) async {
  //   return await db!.delete(Agent.tableagents,
  //       where: '$Agent.col_Agent_Code = ?', whereArgs: [id]);
  // }

  // Future<int> update(Agent data) async {
  //   return await db!.update(Agent.tableagents, data.toMap(),
  //       where: '$Agent.col_Agent_Code = ?', whereArgs: [data.Agent_Code]);
  // }

  // Future close() async => db!.close();
}
