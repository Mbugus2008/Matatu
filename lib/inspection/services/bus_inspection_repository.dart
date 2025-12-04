import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';
import 'package:t_matatu/providers/db.dart';

import '../models/bus_inspection.dart';

class BusInspectionRepository {
  BusInspectionRepository({db_Provider? dbProvider})
      : _dbProvider = dbProvider ?? Get.find<db_Provider>();

  final db_Provider _dbProvider;

  Future<Database> get _database async => _dbProvider.database;

  Future<BusInspection> saveInspection(BusInspection inspection) async {
    final DateTime now = DateTime.now();
    final Database db = await _database;

    if (inspection.id == null) {
      final BusInspection record = inspection.copyWith(
        createdAt: now,
        updatedAt: now,
      );
      final int id = await db.insert(
        BusInspectionTable.table,
        record.toDbMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return record.copyWith(id: id);
    }

    final BusInspection record = inspection.copyWith(updatedAt: now);
    await db.update(
      BusInspectionTable.table,
      record.toDbMap(),
      where: '${BusInspectionTable.colId} = ?',
      whereArgs: <Object?>[record.id],
    );
    return record;
  }

  Future<List<BusInspection>> fetchAllInspections() async {
    final Database db = await _database;
    final List<Map<String, dynamic>> rows = await db.query(
      BusInspectionTable.table,
      orderBy: '${BusInspectionTable.colInspectionDate} DESC',
    );
    return rows.map(BusInspection.fromDbMap).toList();
  }

  Future<List<BusInspection>> fetchPendingInspections() async {
    final Database db = await _database;
    final List<Map<String, dynamic>> rows = await db.query(
      BusInspectionTable.table,
      where: '${BusInspectionTable.colIsSynced} = ?',
      whereArgs: const <Object?>[0],
      orderBy: '${BusInspectionTable.colInspectionDate} DESC',
    );
    return rows.map(BusInspection.fromDbMap).toList();
  }

  Future<BusInspection?> fetchInspectionById(int id) async {
    final Database db = await _database;
    final List<Map<String, dynamic>> rows = await db.query(
      BusInspectionTable.table,
      where: '${BusInspectionTable.colId} = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return BusInspection.fromDbMap(rows.first);
  }

  Future<void> markInspectionSynced(int id) async {
    final Database db = await _database;
    await db.update(
      BusInspectionTable.table,
      <String, Object?>{
        BusInspectionTable.colIsSynced: 1,
        BusInspectionTable.colUpdatedAt: DateTime.now().toIso8601String(),
      },
      where: '${BusInspectionTable.colId} = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> deleteInspection(int id) async {
    final Database db = await _database;
    await db.delete(
      BusInspectionTable.table,
      where: '${BusInspectionTable.colId} = ?',
      whereArgs: <Object?>[id],
    );
  }
}
