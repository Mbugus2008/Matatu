// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';
import 'package:t_matatu/models/Header.dart';
import 'package:t_matatu/models/Hires.dart';
import 'package:t_matatu/models/Reversal.dart';
import 'package:t_matatu/models/Tamounts.dart';
import 'package:t_matatu/models/Transaction.dart' as tmatatu;
import 'package:t_matatu/models/accounttypes.dart';
import 'package:t_matatu/models/agents.dart';
import 'package:t_matatu/models/expenses/expenses.dart';
import 'package:t_matatu/models/mappings.dart';
import 'package:t_matatu/models/member.dart';
import 'package:t_matatu/models/trantypes.dart';

import '../models/Utils/util.dart';
import '../models/expenses/vehicle_expenses.dart';
import '../models/route.dart';
import '../models/vehicles/Vehicle_crew.dart';
import '../models/vehicles/vehicle.dart';
import '../models/weighbridge/wbridge.dart';
import '../pages/disfuel_summary.dart';

class Dbtrans {
  String table;
  Map<String, Object> values;
  Dbtrans({
    required this.table,
    required this.values,
  });
}

class db_Provider extends GetxController {
  Database? _database;
  // Database get database => _db;
  RxList<Dbtrans> transactions = <Dbtrans>[].obs;
  List<AbsDbUpdates> Dbupdate = [
    Member(),
    TranTypes(),
    Header(),
    Tamounts(),
    Expenses(),
    Vehicle_Expenses(),
    Account_Types(),
    Reversal(),
    Hires()
  ];
  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await open();
    await _ensureNewTables(_database!);
    return _database!;
  }

  @override
  Future<void> onInit() async {
    super.onInit();
    //await open();
  }

  Future initialize() async {
    await open();
  }

  Future<Database> open() async {
    //"Mbranch", 2
    List<DbUpdate>? upp = <DbUpdate>[];
    for (AbsDbUpdates up in Dbupdate) {
      if (up.updates()!.isNotEmpty) upp.addAll(up.updates()!.toList());
    }
    upp!.sort((a, b) => b.version!.compareTo(a.version as num));
    return await openDatabase("Mbranch", version: upp[0].version,
        onCreate: (Database db, int version) async {
      await db.execute(Vehicles.createtable);
      await db.execute(Agent.createtable);
      await db.execute(Header.createtable);
      await db.execute(tmatatu.Trans.createtable);
      await db.execute(Member.createtable);
      await db.execute(TranTypes.createtable);
      await db.execute(Vehicle_Crew.createtable);
      await db.execute(Tamounts.createtable);
      await db.execute(Expenses.createtable);
      await db.execute(Vehicle_Expenses.createtable);
      await db.execute(Account_Types.createtable);
      await db.execute(Reversal.createtable);
      await db.execute(Hires.createtable);
      await db.execute(WBridge.createtable);
      await db.execute(RouteModel.createtable);
      await db.execute(DisFuelSummary.createtable);
    }, onUpgrade: _onUpgrade);
  }

  /// Ensure recent tables exist even for existing databases.
  Future<void> _ensureNewTables(Database db) async {
    await db.execute(WBridge.createtable);
    await db.execute(RouteModel.createtable);
    await db.execute(DisFuelSummary.createtable);
  }

  Future<void> close() async {
    if (_database != null) await _database!.close();
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Ensure new tables exist on upgrade (safe with IF NOT EXISTS)
    await db.execute(WBridge.createtable);
    await db.execute(RouteModel.createtable);

    for (var i = oldVersion; i <= newVersion; i++) {
      for (var element in get_updates(newVersion)) {
        try {
          await db.execute(element);
        } catch (e) {}
      }
    }
  }

  Future<T> insert<T extends mapping>(String table, T data) async {
    if (_database == null || _database!.isOpen == false) {
      await database;
    }
    await _database!.transaction((txn) async {
      txn.insert(table, data.toMap_fortable(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    });

    // await Get.find<db_Provider>().database.insert(table, data.toMap_fortable(),
    //     conflictAlgorithm: ConflictAlgorithm.replace);
    //close();
    return data;
  }

  Batch batch() {
    if (_database == null) throw Exception("DB not initialized");
    return _database!.batch();
  }

  Future<List<T>> batchinsert<T extends mapping>(
      String table, List<T> data) async {
    if (_database == null || _database!.isOpen == false) {
      await database;
    }
    await _database!.transaction((txn) async {
      for (T entry in data) {
        txn.insert(table, entry.toMap_fortable(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });

    return data;
  }

  Future<void> batchdelete<T extends mapping>(String table) async {
    try {
      if (_database == null || _database!.isOpen == false) {
        await database;
      }

      await _database!.transaction((txn) async {
        await txn.delete(
          table,
          where: '1=1',
        );
      });
    } catch (e) {
      e.printError();
    }
  }
  // Future<void> transactionprocess() async {
  //   List<Dbtrans> transaction = List.from(Get.find<db_Provider>().transactions);
  //   Get.find<db_Provider>().transactions.clear();
  //   await db_Provider().open();
  //   await database.transaction((txn) async {
  //     transaction.forEach((element) async {
  //       await txn.insert(element.table, element.values,
  //           conflictAlgorithm: ConflictAlgorithm.replace);
  //     });
  //   });
  // }
  // Future<int> update<T extends mapping>(
  //     T data, String table, String where, List<String> whereargs) async {
  //   if (_isDatabaseOpen == false) await open();
  //   return await db!.update(table, data.toMap_fortable(),
  //       where: '$where = ?', whereArgs: whereargs);
  // }

  // Future<int> delete(String table, String where, List<String> whereargs) async {
  //   return await database!
  //       .delete(table, where: '$where = ?', whereArgs: whereargs);
  // }

  Future<List<Map<String, dynamic>>> gettrans(List<String>? cols, String table,
      String where, List<dynamic> args) async {
    return getdata(table, cols, '$where=?', [args]);
    //return maps;

    //  final List<Map<String, dynamic>> maps = await Get.find<db_Provider>()
    //     .database
    //     .query(table, columns: cols, where: '$where=?', whereArgs: args);
    // return maps;
  }

  Future<void> updatedata(String table, Map<String, Object?> updates, String w,
      List<String> args) async {
    if (_database == null || _database!.isOpen == false) {
      await database;
    }
    await _database!.transaction((txn) async {
      try {
        await txn.update(table, updates,
            where: w,
            whereArgs: args,
            conflictAlgorithm: ConflictAlgorithm.replace);
      } catch (e) {
        // Handle exceptions and rollback the transaction if an error occurs
        throw Exception('Error fetching data: $e');
      }
    });

    // final List<Map<String, dynamic>> maps =
    //     await Get.find<db_Provider>().database.query(table, columns: columns);
    // return maps;
  }

  Future<List<Map<String, dynamic>>> getdata(
      String table, List<String>? columns,
      [String? where, List<Object>? args]) async {
    List<Map<String, dynamic>> data = [];

    if (_database == null || _database!.isOpen == false) {
      await database;
    }
    //_showErrorSnackbar('Open Db');
    await _database!.transaction((txn) async {
      try {
        if (where == null) {
          data = await txn.query(table, columns: columns);
        } else {
          data = await txn.query(table,
              columns: columns, where: where, whereArgs: args);
        }
        //_showErrorSnackbar('Opened Db');
      } catch (e) {
        // Handle exceptions and rollback the transaction if an error occurs
        throw Exception('Error fetching data: $e');
      }
    });
    return data;
    // final List<Map<String, dynamic>> maps =
    //     await Get.find<db_Provider>().database.query(table, columns: columns);
    // return maps;
  }

  Future<List<Map<String, dynamic>>> getrawdata(String sql) async {
    List<Map<String, dynamic>> data = [];
    if (_database == null || _database!.isOpen == false) {
      await database;
    }
    await _database!.transaction((txn) async {
      try {
        data = await txn.rawQuery(sql);
      } catch (e) {
        // Handle exceptions and rollback the transaction if an error occurs
        throw Exception('Error fetching data: $e');
      }
    });
    return data;
    // final List<Map<String, dynamic>> maps =
    //     await Get.find<db_Provider>().database.query(table, columns: columns);
    // return maps;
  }

  Future<List<Map<String, dynamic>>> getalltrans(
      List<String>? columns, String table) async {
    final List<Map<String, dynamic>> maps = await getdata(
      table,
      columns,
    );
    return maps;
  }

  Future<List<Map<String, dynamic>>> getpendingheadertrans(
      List<String>? columns, String table) async {
    // final List<Map<String, dynamic>> maps = await Get.find<db_Provider>()
    //     .database
    //     .query(table,
    //         columns: columns,
    //         where: '${Header.col_Sent}=0 or ${Header.col_Sent} IS NULL');
    return getdata(
        table, columns, '${Header.col_Sent}=0 or ${Header.col_Sent} IS NULL');

    // return maps;
  }

  Future<List<Map<String, dynamic>>> getpendingtrans(
      List<String>? columns, String table) async {
    return getdata(table, columns,
        '${tmatatu.Trans.col_sent}=0 or ${tmatatu.Trans.col_sent} IS NULL');

    // final List<
    //     Map<String,
    //         dynamic>> maps = await Get.find<db_Provider>().database.query(table,
    //     columns: columns,
    //     where:
    //         '${tmatatu.Trans.col_sent}=0 or ${tmatatu.Trans.col_sent} IS NULL');
    // return maps;
  }

  Future<List<Map<String, dynamic>>> getrectrans(
      List<String>? columns, String table, String recno) async {
    return getdata(table, columns, '${tmatatu.Trans.col_OTTN}=?', [recno]);

//  final List<Map<String, dynamic>> maps = await Get.find<db_Provider>()
//         .database
//         .query(table,
//             columns: columns,
//             where: '${tmatatu.Trans.col_OTTN}=?',
//             whereArgs: [recno]);
//     return maps;
  }

  Future<List<Map<String, dynamic>>> getvehiclecrews(
      List<String>? columns, String table, String vehicle) async {
    return getdata(table, columns, '${Vehicle_Crew.col_Vehicle}=?', [vehicle]);

    //return maps;

    //     final List<Map<String, dynamic>> maps = await Get.find<db_Provider>()
    //     .database
    //     .query(table,
    //         columns: columns,
    //         where: '${Vehicle_Crew.col_Vehicle}=?',
    //         whereArgs: [vehicle]);
    // return maps;
  }

  Future<List<Map<String, dynamic>>> gettodaytrans(
      List<String>? columns, String table) async {
    return getdata(table, columns, '${Header.col_Date} = ?',
        [getdate().millisecondsSinceEpoch]);

//  final List<Map<String, dynamic>> maps = await Get.find<db_Provider>()
//         .database
//         .query(table,
//             columns: columns,
//             where: '${Header.col_Date} = ?',
//             whereArgs: [getdate().millisecondsSinceEpoch]);
//     return maps;
  }

  Future<List<Map<String, dynamic>>> gettransbydate(
      List<String>? columns, String table, DateTime date) async {
    return getdata(table, columns, '${Header.col_Date} = ?',
        [getdates(date).millisecondsSinceEpoch]);

    //    final List<Map<String, dynamic>> maps = await Get.find<db_Provider>()
    //     .database
    //     .query(table,
    //         columns: columns,
    //         where: '${Header.col_Date} = ?',
    //         whereArgs: [getdates(date).millisecondsSinceEpoch]);
    // return maps;
  }

  Future<List<Map<String, dynamic>>> rawquery(String query) async {
    final List<Map<String, dynamic>> maps = await getrawdata(query);
    return maps;
  }

  Future<List<Map<String, dynamic>>> getvehicles(
      List<String>? columns, String table) async {
    return getdata(table, columns);

    // final List<Map<String, dynamic>> maps =
    //     await Get.find<db_Provider>().database.query(table, columns: columns);
    // return maps;
  }

  Future<List<Map<String, dynamic>>> getmembers(
      List<String>? columns, String table) async {
    return getdata(table, columns);

    // final List<Map<String, dynamic>> maps =
    //     await Get.find<db_Provider>().database.query(table, columns: columns);
    // return maps;
  }

  Future<Map<String, dynamic>?> getagent(
      List<String>? columns, String table, String agent) async {
    List<Map<String, dynamic>> d = await getdata(
        table, columns, '${Agent.col_Agent_Code} = ?', [agent.toUpperCase()]);

    if (d.isEmpty) return null;
    return d.first;

    //await db!.close();

    // .database
    //     .query(table,
    //         columns: columns,
    //         where: '${Agent.col_Agent_Code} = ?',
    //         whereArgs: [agent.toUpperCase()],
    //         limit: 1);
    // //await db!.close();
    // return maps.isNotEmpty ? maps.first : null;
  }

  List<String> get_updates(int version) {
    List<String>? updates = [];
    for (AbsDbUpdates up in Dbupdate) {
      List<DbUpdate>? upp = up.updates();
      DbUpdate? pp = DbUpdate();
      if (upp != null) {
        pp = upp.firstWhereOrNull((element) => element.version == version);
      }

      if (pp != null) {
        updates.addAll(pp.updates!.toList());
      }
    }
    return updates;
  }
}

abstract class AbsDbUpdates {
  List<DbUpdate>? updates();
}

class DbUpdate {
  int? version;
  List<String>? updates;
  DbUpdate({
    this.version,
    this.updates,
  });
}
