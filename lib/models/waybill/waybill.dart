// ignore_for_file: public_member_api_docs, sort_constructors_first
// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:get/get.dart';
import 'package:t_matatu/controllers/waybill_controller.dart';
import 'package:t_matatu/models/mappings.dart';
import 'package:t_matatu/models/member.dart';
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
class WaybillTrip extends Tomaps implements mapping {
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
  bool sent = false;

  /// Local key of the parent waybill entry. Used to link a trip saved before
  /// the waybill was synced (its BC Entry_No is not known yet).
  String? Waybill_Key;

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
    this.sent = false,
    this.Waybill_Key,
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
      From_Time: _parseTripDate(map['From_Time']),
      To: map['To'] as String?,
      To_Time: _parseTripDate(map['To_Time']),
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

  /// Parse a date field that may be a String (API) or int milliseconds (DB).
  static DateTime? _parseTripDate(dynamic value) {
    if (value == null) return null;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  WaybillTrip fromMap_table(Map<String, dynamic> map) =>
      WaybillTrip.fromMap(map);

  /// Local SQLite row (offline-first). 'From'/'To' are SQL keywords, so the
  /// local columns are stored as From_Route / To_Route.
  @override
  Map<String, dynamic> toMap_fortable() {
    return <String, dynamic>{
      'Key': Key ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'Weign_Bridge_id': Weign_Bridge_id,
      'Trip_No': Trip_No,
      'From_Route': From,
      'From_Time': From_Time?.millisecondsSinceEpoch,
      'To_Route': To,
      'To_Time': To_Time?.millisecondsSinceEpoch,
      'Pax_No': Pax_No,
      'Fare_Amount': Fare_Amount,
      'Total': Total,
      'Started_By': Started_By,
      'Ended_by': Ended_by,
      'Amount_Received': Amount_Received,
      'Expenses': Expenses,
      'Comments': Comments,
      'sent': sent ? 1 : 0,
      'Waybill_Key': Waybill_Key,
    };
  }

  // ──────── Database ────────
  static const String table = 'waybill_trip';
  static const String col_Key = 'Key';
  static const String col_Weign_Bridge_id = 'Weign_Bridge_id';
  static const String col_Waybill_Key = 'Waybill_Key';
  static const String col_Trip_No = 'Trip_No';
  static const String col_From = 'From_Route';
  static const String col_From_Time = 'From_Time';
  static const String col_To = 'To_Route';
  static const String col_To_Time = 'To_Time';
  static const String col_Pax_No = 'Pax_No';
  static const String col_Fare_Amount = 'Fare_Amount';
  static const String col_Total = 'Total';
  static const String col_Started_By = 'Started_By';
  static const String col_Ended_by = 'Ended_by';
  static const String col_Amount_Received = 'Amount_Received';
  static const String col_Expenses = 'Expenses';
  static const String col_Comments = 'Comments';
  static const String col_sent = 'sent';

  static const List<String> columns = [
    col_Key,
    col_Weign_Bridge_id,
    col_Waybill_Key,
    col_Trip_No,
    col_From,
    col_From_Time,
    col_To,
    col_To_Time,
    col_Pax_No,
    col_Fare_Amount,
    col_Total,
    col_Started_By,
    col_Ended_by,
    col_Amount_Received,
    col_Expenses,
    col_Comments,
    col_sent,
  ];

  static const String createtable = '''
    CREATE TABLE IF NOT EXISTS $table (
      $col_Key TEXT PRIMARY KEY,
      $col_Weign_Bridge_id INTEGER,
      $col_Waybill_Key TEXT,
      $col_Trip_No INTEGER,
      $col_From TEXT,
      $col_From_Time INTEGER,
      $col_To TEXT,
      $col_To_Time INTEGER,
      $col_Pax_No INTEGER,
      $col_Fare_Amount REAL,
      $col_Total REAL,
      $col_Started_By TEXT,
      $col_Ended_by TEXT,
      $col_Amount_Received TEXT,
      $col_Expenses REAL,
      $col_Comments TEXT,
      $col_sent INTEGER DEFAULT 0
    )
  ''';

  String toJson() => json.encode(toMap());
  factory WaybillTrip.fromJson(String source) =>
      WaybillTrip.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Create from DB row (millisecond timestamps, From_Route/To_Route columns).
  factory WaybillTrip.fromMap_db(Map<String, dynamic> map) {
    final trip = WaybillTrip.fromMap({
      ...map,
      'From': map[col_From],
      'To': map[col_To],
    });
    trip.sent = (map[col_sent] as int?) == 1;
    trip.Waybill_Key = map[col_Waybill_Key] as String?;
    return trip;
  }
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
        'waybills',
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

  /// The existing entry for [vehicleNo]/[fleetNo] on [date], if any.
  /// Business rule: one waybill per vehicle per day (trips are unlimited).
  /// Rows are matched on plate or fleet number, ignoring case and spaces.
  Future<Waybill?> findEntryForVehicle({
    String? vehicleNo,
    String? fleetNo,
    required DateTime date,
    String? excludeKey,
  }) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final rows = await db_Provider().getdata(
        Waybill.table,
        Waybill.columns,
        '${Waybill.col_Date} >= ? AND ${Waybill.col_Date} < ?',
        [startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch],
      );

      final plate = _norm(vehicleNo);
      final fleet = _norm(fleetNo);
      if (plate.isEmpty && fleet.isEmpty) return null;

      for (final row in rows) {
        final wb = Waybill.fromMap_db(row);
        if (excludeKey != null && wb.Key == excludeKey) continue;
        if (plate.isNotEmpty && _norm(wb.Vehicle_No) == plate) return wb;
        if (fleet.isNotEmpty && _norm(wb.Fleet_No) == fleet) return wb;
      }
      return null;
    } catch (_) {
      // No local DB (e.g. tests) — nothing to compare against.
      return null;
    }
  }

  static String _norm(String? value) =>
      (value ?? '').replaceAll(' ', '').trim().toUpperCase();

  /// Crew number for a name or number, resolved from the local crew list.
  /// BC stores the crew number (Driver/Conductor are 10-char codes), so names
  /// must be converted before a waybill is pushed.
  Future<String?> resolveCrewNo(String? nameOrNumber, {String? vehicle}) async {
    final input = (nameOrNumber ?? '').trim();
    if (input.isEmpty) return null;
    try {
      final rows = await db_Provider().getdata(Member.table, Member.columns);
      final members = rows.map((m) => Member.fromMap(m)).toList();

      final target = _norm(input);
      for (final m in members) {
        if (_norm(m.No) == target) return m.No; // already a crew number
      }

      final byName = members.where((m) => _norm(m.Name) == target).toList();
      if (byName.isEmpty) return null;

      final sameVehicle = byName
          .where((m) => vehicle != null && _norm(m.Vehicle) == _norm(vehicle));
      return (sameVehicle.isNotEmpty ? sameVehicle.first : byName.first).No;
    } catch (_) {
      return null;
    }
  }

  /// Converts crew names stored by older builds into crew numbers, and clears a
  /// wrongly-set [Waybill.sent] flag (BC never confirmed those entries), so the
  /// rows are retried instead of being stuck forever.
  Future<int> normalizeCrewNumbers() async {
    try {
      final db = db_Provider();
      final rows = await db.getdata(Waybill.table, Waybill.columns);

      var fixed = 0;
      for (final row in rows) {
        final wb = Waybill.fromMap_db(row);

        final driverNo = await resolveCrewNo(wb.Driver, vehicle: wb.Vehicle_No);
        final conductorNo =
            await resolveCrewNo(wb.Conductor, vehicle: wb.Vehicle_No);

        final driverChanged = driverNo != null && driverNo != wb.Driver;
        final conductorChanged =
            conductorNo != null && conductorNo != wb.Conductor;
        final wronglySent =
            wb.sent && (wb.Entry_No == null || wb.Entry_No == 0);

        if (!driverChanged && !conductorChanged && !wronglySent) continue;

        if (driverChanged) wb.Driver = driverNo;
        if (conductorChanged) wb.Conductor = conductorNo;
        if (wronglySent) wb.sent = false;

        await db.insert(Waybill.table, wb);
        fixed++;
      }
      return fixed;
    } catch (_) {
      return 0;
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

  /// Serializes a map without null entries. The API's model binder rejects
  /// nulls for non-nullable numeric fields (Entry_No, totals) with HTTP 400.
  String _jsonWithoutNulls(Map<String, dynamic> map) {
    map.removeWhere((_, value) => value == null);
    return json.encode(map);
  }

  /// Background sync for a single entry
  Future<void> _syncSingle(Waybill waybill) async {
    await _pushWaybill(waybill);
  }

  /// Pushes one waybill to BC. Crew are sent as crew numbers (BC's Driver /
  /// Conductor fields are 10-char codes and reject names), and the entry is
  /// only flagged sent once BC returns a real entry number.
  Future<void> _pushWaybill(Waybill waybill) async {
    try {
      final originalKey = waybill.Key;

      final driverNo =
          await resolveCrewNo(waybill.Driver, vehicle: waybill.Vehicle_No);
      final conductorNo =
          await resolveCrewNo(waybill.Conductor, vehicle: waybill.Vehicle_No);
      if (driverNo != null) waybill.Driver = driverNo;
      if (conductorNo != null) waybill.Conductor = conductorNo;

      final map = waybill.toMap();
      if (_isTempKey(map['Key'] as String?)) {
        // Force BC Create for locally-created entries.
        map.remove('Key');
      }
      final response = await _api.postdata(
        'addwaybill',
        _jsonWithoutNulls(map),
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

        // Only a real entry number means BC accepted it — BC leaves Entry_No at
        // zero when it stores nothing usable, and such a row must stay pending
        // so it is pushed again.
        waybill.sent = (waybill.Entry_No ?? 0) > 0;
        await db_Provider().insert(Waybill.table, waybill);

        // Drop the locally-created row once BC gave us its own key, so we do
        // not retry the same waybill as a duplicate create.
        if (originalKey != null &&
            originalKey.isNotEmpty &&
            originalKey != waybill.Key) {
          await db_Provider().deletedata(
              Waybill.table, '${Waybill.col_Key} = ?', [originalKey]);
        }

        if (waybill.sent) {
          // Trips waited for this entry number — push them now.
          syncPendingWaybillTrips();
        }
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
          final originalKey = wb.Key;

          final driverNo =
              await resolveCrewNo(wb.Driver, vehicle: wb.Vehicle_No);
          final conductorNo =
              await resolveCrewNo(wb.Conductor, vehicle: wb.Vehicle_No);
          if (driverNo != null) wb.Driver = driverNo;
          if (conductorNo != null) wb.Conductor = conductorNo;

          final map = wb.toMap();
          if (_isTempKey(map['Key'] as String?)) {
            // Force BC Create for locally-created entries.
            map.remove('Key');
          }
          final response = await _api.postdata(
            'addwaybill',
            _jsonWithoutNulls(map),
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
            // Only a real entry number means BC accepted the entry.
            wb.sent = (wb.Entry_No ?? 0) > 0;
            await db.insert(Waybill.table, wb);

            if (originalKey != null &&
                originalKey.isNotEmpty &&
                originalKey != wb.Key) {
              await db.deletedata(
                  Waybill.table, '${Waybill.col_Key} = ?', [originalKey]);
            }
            if (wb.sent) synced++;
          }
        } catch (_) {
          // Skip failed entries; will retry next sync cycle
        }
      }

      // Waybills now have their entry numbers — push any trips that were
      // waiting on them.
      if (synced > 0) {
        await syncPendingWaybillTrips();
      }
    } catch (_) {
      // DB read failed
    }

    return synced;
  }

  /// Fetch trips for a waybill entry — local first, then merge from BC.
  /// [waybillKey] also matches trips saved before the waybill was synced.
  Future<List<WaybillTrip>> getTrips(int? waybillId,
      {String? waybillKey}) async {
    final local = await _getLocalTrips(waybillId, waybillKey: waybillKey);

    List<WaybillTrip> remote = [];
    // Locally-created waybills have no BC entry number yet — asking the API
    // with a null id returns HTTP 400, so skip it.
    if (waybillId != null) {
      try {
        final body = json.encode({'waybillId': waybillId});
        final response = await _api.postdata(
          'waybilltrips',
          body,
        );
        final result =
            Results<WaybillTrip>.fromJson(response.body, WaybillTrip.fromMap);
        if (result.Code == 0 && result.Contents != null) {
          remote = result.Contents!;
        }
      } catch (_) {
        // API failed — fall back to local
      }
    }

    final db = db_Provider();
    final remoteTripNos = remote.map((t) => t.Trip_No).whereType<int>().toSet();

    final merged = <String, WaybillTrip>{};
    for (final t in local) {
      if (!t.sent && t.Trip_No != null && remoteTripNos.contains(t.Trip_No)) {
        // Same trip is already on BC — drop the local temp row.
        if (t.Key != null) {
          await db.deletedata(
              WaybillTrip.table, '${WaybillTrip.col_Key} = ?', [t.Key!]);
        }
        continue;
      }
      if (t.Key != null) merged[t.Key!] = t;
    }
    for (final t in remote) {
      t.sent = true;
      if (t.Key != null && t.Key!.isNotEmpty) {
        await db.insert(WaybillTrip.table, t);
        merged[t.Key!] = t;
      }
    }

    final list = merged.values.toList()
      ..sort((a, b) {
        final an = a.Trip_No ?? 0;
        final bn = b.Trip_No ?? 0;
        if (an != bn) return an.compareTo(bn);
        final at = a.From_Time?.millisecondsSinceEpoch ?? 0;
        final bt = b.From_Time?.millisecondsSinceEpoch ?? 0;
        return at.compareTo(bt);
      });
    return list;
  }

  /// Local trips for several waybills at once (used by the waybill summary).
  Future<List<WaybillTrip>> getLocalTripsFor(
      List<int> waybillIds, List<String> waybillKeys) async {
    if (waybillIds.isEmpty && waybillKeys.isEmpty) return [];
    try {
      final clauses = <String>[];
      final args = <Object>[];
      if (waybillIds.isNotEmpty) {
        clauses.add('${WaybillTrip.col_Weign_Bridge_id} IN '
            '(${List.filled(waybillIds.length, '?').join(', ')})');
        args.addAll(waybillIds);
      }
      if (waybillKeys.isNotEmpty) {
        clauses.add('${WaybillTrip.col_Waybill_Key} IN '
            '(${List.filled(waybillKeys.length, '?').join(', ')})');
        args.addAll(waybillKeys);
      }

      final rows = await db_Provider().getdata(
        WaybillTrip.table,
        WaybillTrip.columns,
        clauses.join(' OR '),
        args,
      );
      return rows.map((m) => WaybillTrip.fromMap_db(m)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Local rows for a waybill entry. Also matches trips that were saved before
  /// the waybill was synced (linked by [WaybillTrip.Waybill_Key]).
  Future<List<WaybillTrip>> _getLocalTrips(int? waybillId,
      {String? waybillKey}) async {
    try {
      final db = db_Provider();
      String where;
      List<Object> args;
      if (waybillId != null && waybillKey != null) {
        where =
            '${WaybillTrip.col_Weign_Bridge_id} = ? OR ${WaybillTrip.col_Waybill_Key} = ?';
        args = [waybillId, waybillKey];
      } else if (waybillId != null) {
        where = '${WaybillTrip.col_Weign_Bridge_id} = ?';
        args = [waybillId];
      } else if (waybillKey != null) {
        where = '${WaybillTrip.col_Waybill_Key} = ?';
        args = [waybillKey];
      } else {
        return [];
      }

      final rows = await db.getdata(
        WaybillTrip.table,
        WaybillTrip.columns,
        where,
        args,
      );
      return rows.map((m) => WaybillTrip.fromMap_db(m)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Links trips that were saved without a waybill link (older builds / the
  /// snackbar "Start" path) to the only waybill of their day. Without this they
  /// can never be found by the trips list.
  Future<int> repairOrphanTrips() async {
    try {
      final db = db_Provider();
      final orphanRows = await db.getdata(
        WaybillTrip.table,
        WaybillTrip.columns,
        '${WaybillTrip.col_Weign_Bridge_id} IS NULL AND '
        '(${WaybillTrip.col_Waybill_Key} IS NULL OR '
        '${WaybillTrip.col_Waybill_Key} = \'\')',
      );
      if (orphanRows.isEmpty) return 0;

      final waybillRows = await db.getdata(Waybill.table, Waybill.columns);
      final waybills = waybillRows.map((m) => Waybill.fromMap_db(m)).toList();

      var repaired = 0;
      for (final row in orphanRows) {
        final trip = WaybillTrip.fromMap_db(row);
        final when = trip.From_Time ?? trip.To_Time;
        if (when == null) continue;

        // Only adopt when the day is unambiguous — one waybill that day.
        final sameDay = waybills
            .where((w) =>
                w.Date != null &&
                w.Date!.year == when.year &&
                w.Date!.month == when.month &&
                w.Date!.day == when.day)
            .toList();
        if (sameDay.length != 1) continue;

        final wb = sameDay.first;
        trip.Weign_Bridge_id = wb.Entry_No;
        trip.Waybill_Key = wb.Key;
        await db.insert(WaybillTrip.table, trip);
        repaired++;
      }
      return repaired;
    } catch (_) {
      return 0;
    }
  }

  /// Save trip locally first (offline-first), then sync in the background.
  Future<WaybillTrip?> saveTrip(WaybillTrip trip) async {
    final db = db_Provider();

    // Always keep the trip linked to its waybill. Trips started before the
    // waybill reached BC are linked by Waybill_Key; a trip saved without a
    // link becomes an orphan the trips list can never find.
    if (trip.Weign_Bridge_id == null &&
        (trip.Waybill_Key == null || trip.Waybill_Key!.isEmpty)) {
      trip.Waybill_Key = _currentWaybillKey();
    }

    trip.sent = false;
    if (trip.Key == null || trip.Key!.isEmpty) {
      trip.Key = DateTime.now().millisecondsSinceEpoch.toString();
    }
    await db.insert(WaybillTrip.table, trip);

    // Sync to BC in the background — the UI is not blocked.
    _syncTripSingle(trip);

    return trip;
  }

  /// Local key of the waybill currently open in the app, if any. Trips saved
  /// without an explicit link adopt it so they stay findable by the list.
  String? _currentWaybillKey() {
    try {
      if (!Get.isRegistered<WaybillController>()) return null;
      final key = Get.find<WaybillController>().selectedWaybill.value?.Key;
      return (key == null || key.isEmpty) ? null : key;
    } catch (_) {
      return null;
    }
  }

  /// True when the key is a locally-generated millisecond placeholder.
  bool _isTempKey(String? key) {
    if (key == null || key.length != 13) return false;
    return int.tryParse(key) != null;
  }

  /// Local waybill row by its local key (used to resolve pending trips).
  Future<Waybill?> _getWaybillByKey(String? key) async {
    if (key == null || key.isEmpty) return null;
    try {
      final rows = await db_Provider().getdata(
        Waybill.table,
        Waybill.columns,
        '${Waybill.col_Key} = ?',
        [key],
      );
      if (rows.isEmpty) return null;
      return Waybill.fromMap_db(rows.first);
    } catch (_) {
      return null;
    }
  }

  /// Background sync for a single trip.
  Future<void> _syncTripSingle(WaybillTrip trip) async {
    try {
      // A trip can be saved before its waybill has synced. Resolve the BC
      // entry number from the local waybill row, and wait if it is not there.
      if (trip.Weign_Bridge_id == null || trip.Weign_Bridge_id == 0) {
        final waybill = await _getWaybillByKey(trip.Waybill_Key);
        if (waybill?.Entry_No == null || waybill!.Entry_No! <= 0) {
          return; // Stays pending until the waybill syncs properly.
        }
        trip.Weign_Bridge_id = waybill.Entry_No;
        await db_Provider().insert(WaybillTrip.table, trip);
      }

      final map = trip.toMap();
      if (_isTempKey(map['Key'] as String?)) {
        // Force BC Create for locally-created trips.
        map['Key'] = null;
      }
      final response = await _api.postdata(
        'addwaybilltrip',
        _jsonWithoutNulls(map),
      );
      final result =
          Results<WaybillTrip>.fromJson(response.body, WaybillTrip.fromMap);
      if (result.Code == 0 &&
          result.Contents != null &&
          result.Contents!.isNotEmpty) {
        final serverTrip = result.Contents!.first;
        final db = db_Provider();
        final oldKey = trip.Key;
        if (serverTrip.Key != null &&
            serverTrip.Key!.isNotEmpty &&
            serverTrip.Key != oldKey) {
          if (oldKey != null) {
            await db.deletedata(
                WaybillTrip.table, '${WaybillTrip.col_Key} = ?', [oldKey]);
          }
          trip.Key = serverTrip.Key;
        }
        trip.sent = true;
        await db.insert(WaybillTrip.table, trip);
      }
    } catch (_) {
      // Will be picked up by syncPendingWaybillTrips
    }
  }

  /// Sync all pending (unsent) trips to the server.
  Future<int> syncPendingWaybillTrips() async {
    final db = db_Provider();
    int synced = 0;

    try {
      final rows = await db.getdata(
        WaybillTrip.table,
        WaybillTrip.columns,
        '${WaybillTrip.col_sent} = 0',
      );
      final pending = rows.map((m) => WaybillTrip.fromMap_db(m)).toList();

      for (final t in pending) {
        try {
          await _syncTripSingle(t);
          if (t.sent) synced++;
        } catch (_) {
          // Skip failed entries; will retry next sync cycle
        }
      }
    } catch (_) {
      // DB read failed
    }

    return synced;
  }
}
