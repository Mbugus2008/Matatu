// ignore_for_file: public_member_api_docs, sort_constructors_first
// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:t_matatu/models/mappings.dart';
import 'package:t_matatu/network/Apis.dart';
import 'package:t_matatu/network/request.dart';
import 'package:t_matatu/network/results/results.dart';
import 'package:t_matatu/providers/db.dart';

/// Waybill entry model — represents a daily vehicle waybill record
class Waybill extends Tomaps implements mapping {
  String? Key;
  String? Vehicle_No;
  String? Fleet_No;
  String? Driver;
  String? Conductor;
  DateTime? Date;
  DateTime? Start_Time;
  DateTime? Finish_Time;
  double? Target_Revenue;
  double? Actual_Revenue;
  double? Shortage;
  int? Entry_No;
  double? Cash;
  double? Total_Expected;
  double? Total_Collected;
  bool sent = false;

  Waybill({
    this.Key,
    this.Vehicle_No,
    this.Fleet_No,
    this.Driver,
    this.Conductor,
    this.Date,
    this.Start_Time,
    this.Finish_Time,
    this.Target_Revenue,
    this.Actual_Revenue,
    this.Shortage,
    this.Entry_No,
    this.Cash,
    this.Total_Expected,
    this.Total_Collected,
    this.sent = false,
  });

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'Key': Key,
      'Vehicle_No': Vehicle_No,
      'Fleet_No': Fleet_No,
      'Driver': Driver,
      'Conductor': Conductor,
      'Date': Date?.toIso8601String(),
      'Start_Time': Start_Time?.toIso8601String(),
      'Finish_Time': Finish_Time?.toIso8601String(),
      'Target_Revenue': Target_Revenue,
      'Actual_Revenue': Actual_Revenue,
      'Shortage': Shortage,
      'Entry_No': Entry_No,
      'Cash': Cash,
      'Total_Expected': Total_Expected,
      'Total_Collected': Total_Collected,
    };
  }

  static Waybill fromMap(Map<String, dynamic> map) {
    return Waybill(
      Key: map['Key'] as String?,
      Vehicle_No: map['Vehicle_No'] as String?,
      Fleet_No: map['Fleet_No'] as String?,
      Driver: map['Driver'] as String?,
      Conductor: map['Conductor'] as String?,
      Date: _parseDate(map['Date']),
      Start_Time: _parseDate(map['Start_Time']),
      Finish_Time: _parseDate(map['Finish_Time']),
      Target_Revenue: (map['Target_Revenue'] as num?)?.toDouble(),
      Actual_Revenue: (map['Actual_Revenue'] as num?)?.toDouble(),
      Shortage: (map['Shortage'] as num?)?.toDouble(),
      Entry_No: map['Entry_No'] as int?,
      Cash: (map['Cash'] as num?)?.toDouble(),
      Total_Expected: (map['Total_Expected'] as num?)?.toDouble(),
      Total_Collected: (map['Total_Collected'] as num?)?.toDouble(),
    );
  }

  @override
  Waybill fromMap_table(Map<String, dynamic> map) => Waybill.fromMap(map);

  /// Parse a date field that may be a String (API) or int milliseconds (DB).
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  Map<String, dynamic> toMap_fortable() {
    return <String, dynamic>{
      'Key': Key ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'Vehicle_No': Vehicle_No,
      'Fleet_No': Fleet_No,
      'Driver': Driver,
      'Conductor': Conductor,
      'Date': Date?.millisecondsSinceEpoch,
      'Start_Time': Start_Time?.millisecondsSinceEpoch,
      'Finish_Time': Finish_Time?.millisecondsSinceEpoch,
      'Target_Revenue': Target_Revenue,
      'Actual_Revenue': Actual_Revenue,
      'Shortage': Shortage,
      'Entry_No': Entry_No,
      'Cash': Cash,
      'Total_Expected': Total_Expected,
      'Total_Collected': Total_Collected,
      'sent': sent ? 1 : 0,
    };
  }

  // ──────── Database ────────
  // Table name kept as 'wbridge' so existing devices keep their local data.
  static const String table = 'wbridge';
  static const String col_Key = 'Key';
  static const String col_Vehicle_No = 'Vehicle_No';
  static const String col_Fleet_No = 'Fleet_No';
  static const String col_Driver = 'Driver';
  static const String col_Conductor = 'Conductor';
  static const String col_Date = 'Date';
  static const String col_Start_Time = 'Start_Time';
  static const String col_Finish_Time = 'Finish_Time';
  static const String col_Target_Revenue = 'Target_Revenue';
  static const String col_Actual_Revenue = 'Actual_Revenue';
  static const String col_Shortage = 'Shortage';
  static const String col_Entry_No = 'Entry_No';
  static const String col_Cash = 'Cash';
  static const String col_Total_Expected = 'Total_Expected';
  static const String col_Total_Collected = 'Total_Collected';
  static const String col_sent = 'sent';

  static const List<String> columns = [
    col_Key,
    col_Vehicle_No,
    col_Fleet_No,
    col_Driver,
    col_Conductor,
    col_Date,
    col_Start_Time,
    col_Finish_Time,
    col_Target_Revenue,
    col_Actual_Revenue,
    col_Shortage,
    col_Entry_No,
    col_Cash,
    col_Total_Expected,
    col_Total_Collected,
    col_sent,
  ];

  static const String createtable = '''
    CREATE TABLE IF NOT EXISTS $table (
      $col_Key TEXT PRIMARY KEY,
      $col_Vehicle_No TEXT,
      $col_Fleet_No TEXT,
      $col_Driver TEXT,
      $col_Conductor TEXT,
      $col_Date INTEGER,
      $col_Start_Time INTEGER,
      $col_Finish_Time INTEGER,
      $col_Target_Revenue REAL,
      $col_Actual_Revenue REAL,
      $col_Shortage REAL,
      $col_Entry_No INTEGER,
      $col_Cash REAL,
      $col_Total_Expected REAL,
      $col_Total_Collected REAL,
      $col_sent INTEGER DEFAULT 0
    )
  ''';

  String toJson() => json.encode(toMap());
  factory Waybill.fromJson(String source) =>
      Waybill.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Create from DB row (millisecond timestamps).
  /// _parseDate handles both int (DB) and String (API) formats.
  factory Waybill.fromMap_db(Map<String, dynamic> map) {
    final wb = Waybill.fromMap(map);
    wb.sent = (map[col_sent] as int?) == 1;
    return wb;
  }
}

/// Waybill Trip model — represents an individual trip within a waybill entry
class WaybillTrip extends Tomaps {
  String? Key;
  int? Weign_Bridge_id;
  int? Trip_No;
  String? From;
  DateTime? From_Time;
  String? To;
  DateTime? To_Time;
  int? Pax_No;
  double? Fare_Amount;
  double? Total;
  String? Started_By;
  String? Ended_by;
  String? Amount_Received;
  double? Expenses;
  String? Comments;

  WaybillTrip({
    this.Key,
    this.Weign_Bridge_id,
    this.Trip_No,
    this.From,
    this.From_Time,
    this.To,
    this.To_Time,
    this.Pax_No,
    this.Fare_Amount,
    this.Total,
    this.Started_By,
    this.Ended_by,
    this.Amount_Received,
    this.Expenses,
    this.Comments,
  });

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'Key': Key,
      'Weign_Bridge_id': Weign_Bridge_id,
      'Trip_No': Trip_No,
      'From': From,
      'From_Time': From_Time?.toIso8601String(),
      'To': To,
      'To_Time': To_Time?.toIso8601String(),
      'Pax_No': Pax_No,
      'Fare_Amount': Fare_Amount,
      'Total': Total,
      'Started_By': Started_By,
      'Ended_by': Ended_by,
      'Amount_Received': Amount_Received,
      'Expenses': Expenses,
      'Comments': Comments,
    };
  }

  static WaybillTrip fromMap(Map<String, dynamic> map) {
    return WaybillTrip(
      Key: map['Key'] as String?,
      Weign_Bridge_id: map['Weign_Bridge_id'] as int?,
      Trip_No: map['Trip_No'] as int?,
      From: map['From'] as String?,
      From_Time: map['From_Time'] != null
          ? DateTime.tryParse(map['From_Time'] as String)
          : null,
      To: map['To'] as String?,
      To_Time: map['To_Time'] != null
          ? DateTime.tryParse(map['To_Time'] as String)
          : null,
      Pax_No: map['Pax_No'] as int?,
      Fare_Amount: (map['Fare_Amount'] as num?)?.toDouble(),
      Total: (map['Total'] as num?)?.toDouble(),
      Started_By: map['Started_By'] as String?,
      Ended_by: map['Ended_by'] as String?,
      Amount_Received: map['Amount_Received'] as String?,
      Expenses: (map['Expenses'] as num?)?.toDouble(),
      Comments: map['Comments'] as String?,
    );
  }

  @override
  WaybillTrip fromMap_table(Map<String, dynamic> map) =>
      WaybillTrip.fromMap(map);

  String toJson() => json.encode(toMap());
  factory WaybillTrip.fromJson(String source) =>
      WaybillTrip.fromMap(json.decode(source) as Map<String, dynamic>);
}

/// API service for Waybill endpoints.
/// Saves locally first (offline-first), then syncs to server.
class WaybillService {
  final ApiClient _api = ApiClient();

  /// Fetch waybill entries — tries API first, falls back to local DB
  Future<List<Waybill>> getWaybills(DateTime date, {String? vehicle}) async {
    // Try API first
    try {
      final request = Request(date: date, vehicle: vehicle);
      final response = await _api.postdata(
        'Matatu/waybills',
        request.toJson(),
      );
      final result = Results<Waybill>.fromJson(response.body, Waybill.fromMap);
      if (result.Code == 0 && result.Contents != null) {
        return result.Contents!;
      }
    } catch (_) {
      // API failed — fall back to local
    }

    // Fallback: fetch from local DB
    return _getLocalWaybills(date);
  }

  /// Fetch pending (unsent) waybill entries from local DB
  Future<List<Waybill>> _getLocalWaybills(DateTime date) async {
    try {
      final db = db_Provider();
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final rows = await db.getdata(
        Waybill.table,
        Waybill.columns,
        '${Waybill.col_Date} >= ? AND ${Waybill.col_Date} < ?',
        [startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch],
      );
      return rows.map((m) => Waybill.fromMap_db(m)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Save waybill entry — persists locally, then attempts API sync
  Future<Waybill?> saveWaybill(Waybill waybill) async {
    final db = db_Provider();

    // 1. Always save locally first
    waybill.sent = false;
    if (waybill.Key == null || waybill.Key!.isEmpty) {
      waybill.Key = DateTime.now().millisecondsSinceEpoch.toString();
    }
    await db.insert(Waybill.table, waybill);

    // 2. Attempt API sync in background
    _syncSingle(waybill);

    return waybill;
  }

  /// Background sync for a single entry
  Future<void> _syncSingle(Waybill waybill) async {
    try {
      final response = await _api.postdata(
        'Matatu/addwaybill',
        waybill.toJson(),
      );
      final result = Results<Waybill>.fromJson(response.body, Waybill.fromMap);
      if (result.Code == 0 &&
          result.Contents != null &&
          result.Contents!.isNotEmpty) {
        // Keep the BC-assigned Entry_No and Key so trips can link to it.
        final serverWaybill = result.Contents!.first;
        if (serverWaybill.Entry_No != null) {
          waybill.Entry_No = serverWaybill.Entry_No;
        }
        if (serverWaybill.Key != null && serverWaybill.Key!.isNotEmpty) {
          waybill.Key = serverWaybill.Key;
        }
        // Mark as sent in local DB
        waybill.sent = true;
        await db_Provider().insert(Waybill.table, waybill);
      }
    } catch (_) {
      // Will be picked up by syncPendingWaybills later
    }
  }

  /// Sync all pending (unsent) waybill entries to the server
  Future<int> syncPendingWaybills() async {
    final db = db_Provider();
    int synced = 0;

    try {
      final rows = await db.getdata(
        Waybill.table,
        Waybill.columns,
        '${Waybill.col_sent} = 0',
      );
      final pending = rows.map((m) => Waybill.fromMap_db(m)).toList();

      for (final wb in pending) {
        try {
          final response = await _api.postdata(
            'Matatu/addwaybill',
            wb.toJson(),
          );
          final result =
              Results<Waybill>.fromJson(response.body, Waybill.fromMap);
          if (result.Code == 0 &&
              result.Contents != null &&
              result.Contents!.isNotEmpty) {
            // Keep the BC-assigned Entry_No and Key.
            final serverWaybill = result.Contents!.first;
            if (serverWaybill.Entry_No != null) {
              wb.Entry_No = serverWaybill.Entry_No;
            }
            if (serverWaybill.Key != null && serverWaybill.Key!.isNotEmpty) {
              wb.Key = serverWaybill.Key;
            }
            wb.sent = true;
            await db.insert(Waybill.table, wb);
            synced++;
          }
        } catch (_) {
          // Skip failed entries; will retry next sync cycle
        }
      }
    } catch (_) {
      // DB read failed
    }

    return synced;
  }

  /// Fetch trips for a specific waybill entry ID
  Future<List<WaybillTrip>> getTrips(int waybillId) async {
    final body = json.encode({'waybillId': waybillId});

    final response = await _api.postdata(
      'Matatu/waybilltrips',
      body,
    );

    final result =
        Results<WaybillTrip>.fromJson(response.body, WaybillTrip.fromMap);

    if (result.Code == 0 && result.Contents != null) {
      return result.Contents!;
    }
    return [];
  }

  /// Create or update a waybill trip
  Future<WaybillTrip?> saveTrip(WaybillTrip trip) async {
    final response = await _api.postdata(
      'Matatu/addwaybilltrip',
      trip.toJson(),
    );

    final result =
        Results<WaybillTrip>.fromJson(response.body, WaybillTrip.fromMap);

    if (result.Code == 0 && result.Contents != null) {
      return result.Contents!.firstOrNull;
    }
    return null;
  }
}
