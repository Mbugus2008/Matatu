// ignore_for_file: public_member_api_docs, sort_constructors_first
// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:t_matatu/controllers/main.dart';
import 'package:t_matatu/controllers/waybill_controller.dart';
import 'package:t_matatu/models/mappings.dart';
import 'package:t_matatu/models/member.dart';
import 'package:t_matatu/models/route.dart';
import 'package:t_matatu/network/Apis.dart';
import 'package:t_matatu/network/request.dart';
import 'package:t_matatu/network/results/results.dart';
import 'package:t_matatu/providers/db.dart';

/// Waybill entry model — represents a daily vehicle waybill record
///
/// Dates arrive in three shapes and all of them have to parse:
/// - Business Central JSON: `MM/dd/yyyy HH:mm:ss` (e.g. `09/29/2026 00:00:00`)
/// - what the app itself sends: ISO-8601
/// - what the local table stores: epoch milliseconds
DateTime? _parseServerDate(dynamic value) {
  if (value == null) return null;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is double) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  if (value is! String) return null;

  final text = value.trim();
  if (text.isEmpty) return null;

  // ISO first - that is what the app writes and what the table returns.
  final iso = DateTime.tryParse(text);
  if (iso != null) return iso;

  // Business Central serialises DateTime fields as MM/dd/yyyy HH:mm:ss.
  const patterns = [
    'MM/dd/yyyy HH:mm:ss',
    'MM/dd/yyyy',
    'M/d/yyyy H:mm:ss',
    'M/d/yyyy',
    'MM/dd/yyyy hh:mm:ss a',
  ];
  DateTime? parsed;
  for (final pattern in patterns) {
    try {
      parsed = DateFormat(pattern).parse(text);
      break;
    } on FormatException {
      continue;
    }
  }
  if (parsed == null) return null;

  // NAV's "empty" date is 01/01/0001. Time-only fields (Start_Time, From_Time,
  // Finish_Time, ...) still carry a useful clock value, so keep it on a neutral
  // day; a midnight value means the field is simply not set.
  if (parsed.year == 1) {
    final hasTime =
        parsed.hour != 0 || parsed.minute != 0 || parsed.second != 0;
    if (!hasTime) return null;
    return DateTime(1970, 1, 1, parsed.hour, parsed.minute, parsed.second);
  }
  return parsed;
}
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

  /// Receipt that closed this entry's trips — empty until a receipt is
  /// printed while the entry still had open trips.
  String? Receipt_No;
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
    this.Receipt_No,
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
      'Receipt_No': Receipt_No,
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
      Receipt_No: map['Receipt_No'] as String?,
    );
  }

  @override
  Waybill fromMap_table(Map<String, dynamic> map) => Waybill.fromMap(map);

  /// Parse a date field that may be a String (API) or int milliseconds (DB).
  static DateTime? _parseDate(dynamic value) => _parseServerDate(value);

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
      'Receipt_No': Receipt_No,
      'sent': sent ? 1 : 0,
    };
  }

  // ──────── Database ────────
  // Local table for the waybill header. Older builds called it 'wbridge';
  // db.dart moves those rows across on first open.
  static const String table = 'wbill';
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
  static const String col_Receipt_No = 'Receipt_No';
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
    col_Receipt_No,
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
      $col_Receipt_No TEXT,
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

  /// Route description of [From] (e.g. "Kencom - Kawangware"). NAV stores it
  /// on the trip for reporting; filled from the local route list.
  String? Description;
  bool sent = false;

  /// Local key of the parent waybill entry. Used to link a trip saved before
  /// the waybill was synced (its BC Entry_No is not known yet).
  String? Waybill_Key;

  /// True while the trip holds local edits BC has not accepted yet. Set by
  /// [WaybillService.saveTrip], cleared when BC takes the trip, and the delta
  /// sync never overwrites a dirty trip.
  bool dirty = false;

  /// A trip is open until it is closed with an end time. Expenses may only be
  /// recorded while the trip is open.
  bool get isOpen => To_Time == null;

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
    this.Description,
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
      'Description': Description,
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
      Description: map['Description'] as String?,
    );
  }

  /// Parse a date field that may be a String (API) or int milliseconds (DB).
  static DateTime? _parseTripDate(dynamic value) => _parseServerDate(value);

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
      'Description': Description,
      'sent': sent ? 1 : 0,
      'Dirty': dirty ? 1 : 0,
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
  static const String col_Description = 'Description';
  static const String col_Dirty = 'Dirty';
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
    col_Description,
    col_Dirty,
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
      $col_Description TEXT,
      $col_Dirty INTEGER DEFAULT 0,
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
    trip.dirty = (map[col_Dirty] as int?) == 1;
    trip.Waybill_Key = map[col_Waybill_Key] as String?;
    return trip;
  }
}

/// How a local trip row meets BC's copy when the trip list is fetched.
enum TripSyncDisposition {
  /// Never-synced local row (temp key) whose trip already exists on BC — a
  /// create whose reply was lost; the local row is redundant.
  dropTemp,

  /// Synced local row whose BC record moved on (the key's version suffix
  /// differs). BC's copy is the newer one — drop the stale local row so one
  /// trip never shows twice.
  dropStale,

  /// Local edit still waiting to push (a close, an expense, a comment).
  /// BC's copy is older until the push lands — keep the edit and do not let
  /// the server copy overwrite it.
  keepEdit,

  /// Local and server agree — keep the row; the server copy may refresh it.
  keep,
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
        // Keep what came down: the list then works offline, and
        // findEntryForVehicle() sees entries raised on other devices.
        await _cacheServerWaybills(result.Contents!);
        return result.Contents!;
      }
    } catch (_) {
      // API failed — fall back to local
    }

    // Fallback: fetch from local DB
    return _getLocalWaybills(date);
  }

  /// Stores waybills that came from BC locally, flagged as already sent so the
  /// sync loop never posts them back.
  Future<void> _cacheServerWaybills(List<Waybill> waybills) async {
    if (waybills.isEmpty) return;
    for (final wb in waybills) {
      wb.sent = true;
    }
    try {
      await db_Provider().batchinsert(Waybill.table, waybills);
    } catch (_) {
      // Caching is best-effort - the caller already has the rows.
    }
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
      if (isTempKey(map['Key'] as String?)) {
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

        // Trips saved while this entry was still local point at its temp
        // key — re-point them at the BC key and entry number BEFORE the
        // temp row disappears, or they can never resolve.
        if (originalKey != null &&
            originalKey.isNotEmpty &&
            originalKey != waybill.Key) {
          await _relinkTripsToNewKey(originalKey, waybill);
        }

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
          if (isTempKey(map['Key'] as String?)) {
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
              await _relinkTripsToNewKey(originalKey, wb);
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

    // BC's current copy of each trip, by trip number. It anchors both sides
    // of the merge: a local row whose BC record moved on (NAV changes the
    // key's version suffix on every edit) is a stale copy, and a server copy
    // must never overwrite a local edit whose push is still in flight.
    final remoteByTripNo = <int, WaybillTrip>{};
    for (final t in remote) {
      final no = t.Trip_No;
      if (no != null) remoteByTripNo[no] = t;
    }

    final merged = <String, WaybillTrip>{};
    final protectedTripNos = <int>{};

    for (final t in local) {
      final remoteCopy = t.Trip_No == null ? null : remoteByTripNo[t.Trip_No!];
      switch (tripDisposition(local: t, remote: remoteCopy)) {
        case TripSyncDisposition.dropTemp:
        case TripSyncDisposition.dropStale:
          // One trip, one row: either the temp row already reached BC under
          // another key, or BC holds a newer version of this record.
          if (t.Key != null) {
            await db.deletedata(
                WaybillTrip.table, '${WaybillTrip.col_Key} = ?', [t.Key!]);
          }
          break;
        case TripSyncDisposition.keepEdit:
          // A close/expense/comment not pushed yet — BC's copy is older.
          // Keep the edit and stop the server copy replacing it.
          if (t.Trip_No != null) protectedTripNos.add(t.Trip_No!);
          if (t.Key != null) merged[t.Key!] = t;
          break;
        case TripSyncDisposition.keep:
          if (t.Key != null) merged[t.Key!] = t;
          break;
      }
    }

    for (final t in remote) {
      if (t.Trip_No != null && protectedTripNos.contains(t.Trip_No)) {
        // A local edit is still waiting to push — it wins until then.
        continue;
      }
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

  /// Preference key holding the last trip number this device handed out.
  static const String _lastTripNoKey = 'waybill_trip_last_no';

  /// The next trip number given the numbers already known on the device and
  /// [lastIssued], the last number this device handed out. Numbers
  /// auto-increment across every waybill — a trip id never restarts per
  /// entry and a deleted trip's number is never re-used.
  static int nextNumberFrom(Iterable<int?> tripNos, int lastIssued) {
    var highest = lastIssued;
    for (final no in tripNos) {
      if (no != null && no > highest) highest = no;
    }
    return highest + 1;
  }

  /// Next trip number for a new trip. One sequence across all waybills:
  /// trips are numbered 1, 2, 3, … on the device, never restarting under a
  /// new entry. The issued number is persisted so the sequence keeps going up
  /// even when older trip rows are gone locally. [entryNo]/[waybillKey] are
  /// kept for call-site compatibility; they no longer scope the sequence.
  Future<int> nextTripNo(int? entryNo, {String? waybillKey}) async {
    final numbers = <int?>[];
    try {
      final rows = await db_Provider()
          .getdata(WaybillTrip.table, const [WaybillTrip.col_Trip_No]);
      numbers.addAll(rows
          .map((row) => row[WaybillTrip.col_Trip_No])
          .whereType<int>());
    } catch (_) {
      // No local rows (or no DB) — the stored counter still carries on.
    }

    var lastIssued = 0;
    try {
      if (Get.isRegistered<MainController>()) {
        final stored =
            await Get.find<MainController>().getPreference(_lastTripNoKey);
        lastIssued = int.tryParse(stored ?? '') ?? 0;
      }
    } catch (_) {}

    final next = nextNumberFrom(numbers, lastIssued);
    try {
      if (Get.isRegistered<MainController>()) {
        await Get.find<MainController>()
            .savePreference(_lastTripNoKey, next.toString());
      }
    } catch (_) {}
    return next;
  }

  /// Open trips (no end time) for [vehicleNo]: their count, the sum of their
  /// totals and the sum of their expenses, across every entry — a trip left
  /// open overnight is still on the road. The receipt shows this so the
  /// officer can see the money the vehicle still has before it is closed out.
  Future<(int, double, double)> openTripsSummaryForVehicle({
    required String vehicleNo,
  }) async {
    final vehicle = vehicleNo.trim().toUpperCase();
    if (vehicle.isEmpty) return (0, 0.0, 0.0);
    try {
      final db = db_Provider();
      final wbRows = await db.getdata(Waybill.table, Waybill.columns);
      final entries = wbRows.map(Waybill.fromMap_db).where((w) {
        return (w.Vehicle_No ?? '').trim().toUpperCase() == vehicle;
      }).toList();
      if (entries.isEmpty) return (0, 0.0, 0.0);

      final tripRows = await db.getdata(
        WaybillTrip.table,
        WaybillTrip.columns,
        '${WaybillTrip.col_To_Time} IS NULL',
      );
      final trips = <WaybillTrip>[];
      for (final t in tripRows.map(WaybillTrip.fromMap_db)) {
        for (final e in entries) {
          final sameEntry =
              (e.Entry_No != null &&
                  e.Entry_No! > 0 &&
                  t.Weign_Bridge_id == e.Entry_No) ||
              (e.Key != null &&
                  e.Key!.isNotEmpty &&
                  t.Waybill_Key == e.Key);
          if (sameEntry) {
            trips.add(t);
            break;
          }
        }
      }
      return openTripsSummary(trips);
    } catch (_) {
      return (0, 0.0, 0.0);
    }
  }

  /// Every trip recorded for [vehicleNo] across its entries — open and closed
  /// — ordered by trip number. Drives the receipt page's trip-details popup.
  Future<List<WaybillTrip>> tripsForVehicle({required String vehicleNo}) async {
    final vehicle = vehicleNo.trim().toUpperCase();
    if (vehicle.isEmpty) return const [];
    try {
      final db = db_Provider();
      final wbRows = await db.getdata(Waybill.table, Waybill.columns);
      final entries = wbRows.map(Waybill.fromMap_db).where((w) {
        return (w.Vehicle_No ?? '').trim().toUpperCase() == vehicle;
      }).toList();
      if (entries.isEmpty) return const [];

      final tripRows = await db.getdata(WaybillTrip.table, WaybillTrip.columns);
      final trips = <WaybillTrip>[];
      for (final t in tripRows.map(WaybillTrip.fromMap_db)) {
        for (final e in entries) {
          final sameEntry =
              (e.Entry_No != null &&
                  e.Entry_No! > 0 &&
                  t.Weign_Bridge_id == e.Entry_No) ||
              (e.Key != null &&
                  e.Key!.isNotEmpty &&
                  t.Waybill_Key == e.Key);
          if (sameEntry) {
            trips.add(t);
            break;
          }
        }
      }
      trips.sort((a, b) => (a.Trip_No ?? 0).compareTo(b.Trip_No ?? 0));
      return trips;
    } catch (_) {
      return const [];
    }
  }

  /// (count, total, expenses) across the open trips in [trips]. Null values
  /// count as 0.
  static (int, double, double) openTripsSummary(Iterable<WaybillTrip> trips) {
    var count = 0;
    var total = 0.0;
    var expenses = 0.0;
    for (final trip in trips) {
      if (!trip.isOpen) continue;
      count++;
      total += trip.Total ?? 0;
      expenses += trip.Expenses ?? 0;
    }
    return (count, total, expenses);
  }

  /// Closes every open trip of [vehicleNo] (all entries). Run after a receipt
  /// is printed: whatever was on the road is handed in with that receipt.
  /// Each close goes through saveTrip, so it is marked dirty locally and
  /// pushed to BC in the background until accepted. When [receiptNo] is
  /// given, every entry whose trips were closed is stamped with it so the
  /// chain trip -> entry -> receipt stays traceable. When [amountReceived]
  /// is given (the printed receipt's total) it is written onto the trips as
  /// their Amount_Received — split across the trips via [allocateReceived].
  Future<int> closeOpenTrips(
      {required String vehicleNo,
      String? receiptNo,
      double? amountReceived}) async {
    final vehicle = vehicleNo.trim().toUpperCase();
    if (vehicle.isEmpty) return 0;
    try {
      final db = db_Provider();
      final wbRows = await db.getdata(Waybill.table, Waybill.columns);
      final entries = wbRows.map(Waybill.fromMap_db).where((w) {
        return (w.Vehicle_No ?? '').trim().toUpperCase() == vehicle;
      }).toList();
      if (entries.isEmpty) return 0;

      final tripRows = await db.getdata(
        WaybillTrip.table,
        WaybillTrip.columns,
        '${WaybillTrip.col_To_Time} IS NULL',
      );

      // Collect first: the receipt amount is split across the trips (in trip
      // order) before any of them is saved.
      final toClose = <WaybillTrip>[];
      final touched = <Waybill>{};
      for (final t in tripRows.map(WaybillTrip.fromMap_db)) {
        Waybill? entry;
        for (final e in entries) {
          final belongs = (e.Entry_No != null &&
                  e.Entry_No! > 0 &&
                  t.Weign_Bridge_id == e.Entry_No) ||
              (e.Key != null && e.Key!.isNotEmpty && t.Waybill_Key == e.Key);
          if (belongs) {
            entry = e;
            break;
          }
        }
        if (entry == null) continue;
        toClose.add(t);
        touched.add(entry);
      }
      if (toClose.isEmpty) return 0;
      toClose.sort((a, b) {
        final af = a.From_Time;
        final bf = b.From_Time;
        if (af != null && bf != null) {
          final c = af.compareTo(bf);
          if (c != 0) return c;
        } else if (af != null) {
          return -1;
        } else if (bf != null) {
          return 1;
        }
        return (a.Trip_No ?? 0).compareTo(b.Trip_No ?? 0);
      });

      final received = (amountReceived != null && amountReceived > 0)
          ? allocateReceived(
              amountReceived, toClose.map((t) => t.Total).toList())
          : const <double>[];

      final now = DateTime.now();
      var closed = 0;
      for (var i = 0; i < toClose.length; i++) {
        final t = toClose[i];
        t.To_Time =
            DateTime(now.year, now.month, now.day, now.hour, now.minute);
        if (received.isNotEmpty) {
          final v = received[i];
          t.Amount_Received = v == v.roundToDouble()
              ? v.toStringAsFixed(0)
              : v.toStringAsFixed(2);
        }
        await saveTrip(t);
        closed++;
      }

      final trace = (receiptNo ?? '').trim();
      if (trace.isNotEmpty) {
        for (final entry in touched) {
          if ((entry.Receipt_No ?? '').trim() == trace) continue;
          entry.Receipt_No = trace;
          await saveWaybill(entry);
        }
      }
      return closed;
    } catch (_) {
      return 0;
    }
  }

  /// Splits a receipt's [amount] across the trips it closes, in trip order:
  /// every trip except the last takes at most its own target (or nothing when
  /// the target is missing); the last trip takes whatever remains, so the
  /// allocations always sum to [amount] exactly. A single closed trip
  /// therefore records the whole receipt total.
  static List<double> allocateReceived(double amount, List<double?> targets) {
    final out = List<double>.filled(targets.length, 0);
    if (targets.isEmpty) return out;
    var remaining = amount;
    for (var i = 0; i < targets.length; i++) {
      if (i == targets.length - 1) {
        out[i] = remaining;
        break;
      }
      final cap = targets[i] ?? 0;
      final take = remaining <= cap ? remaining : cap;
      out[i] = take;
      remaining -= take;
    }
    return out;
  }

  /// Links trips that lost their waybill link to the only waybill of their
  /// day. Two kinds are healed: trips saved with no link at all (older builds
  /// / the snackbar "Start" path), and trips pointing at a local key that no
  /// longer exists (the entry's temp key, replaced by BC's key on sync).
  /// Without this they can never be found by the trips list.
  Future<int> repairOrphanTrips() async {
    try {
      final db = db_Provider();
      final orphanRows = await db.getdata(
        WaybillTrip.table,
        WaybillTrip.columns,
        '${WaybillTrip.col_Weign_Bridge_id} IS NULL',
      );
      if (orphanRows.isEmpty) return 0;

      final waybillRows = await db.getdata(Waybill.table, Waybill.columns);
      final waybills = waybillRows.map((m) => Waybill.fromMap_db(m)).toList();
      final waybillKeys = waybills
          .map((w) => (w.Key ?? '').trim())
          .where((k) => k.isNotEmpty)
          .toSet();

      var repaired = 0;
      for (final row in orphanRows) {
        final trip = WaybillTrip.fromMap_db(row);
        // A trip whose key still resolves waits for that entry's own sync —
        // linking it elsewhere could attach the wrong waybill.
        final tripKey = (trip.Waybill_Key ?? '').trim();
        if (tripKey.isNotEmpty && waybillKeys.contains(tripKey)) continue;

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
    trip.dirty = true;
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
  static bool isTempKey(String? key) {
    if (key == null || key.length != 13) return false;
    return int.tryParse(key) != null;
  }

  /// Decides what happens to a local trip row when BC's copy of the same
  /// trip (if any) is known — pure so the merge rules stay unit-testable.
  ///
  /// NAV bumps the key's version suffix on every edit, so a synced row whose
  /// key no longer matches BC is an old copy of the same record. A row that
  /// still has to push (a close, an expense, a comment) must never be
  /// overwritten by BC's older copy, or the edit silently disappears.
  static TripSyncDisposition tripDisposition({
    required WaybillTrip local,
    required WaybillTrip? remote,
  }) {
    if (local.dirty || !local.sent) {
      final sameTrip = remote != null && remote.Trip_No == local.Trip_No;
      if (sameTrip && isTempKey(local.Key)) {
        // Never-synced local row whose trip is already on BC (the create
        // reached NAV but the reply was lost) — the local row is redundant.
        return TripSyncDisposition.dropTemp;
      }
      return TripSyncDisposition.keepEdit;
    }
    if (remote != null &&
        remote.Key != null &&
        remote.Key!.isNotEmpty &&
        remote.Key != local.Key) {
      return TripSyncDisposition.dropStale;
    }
    return TripSyncDisposition.keep;
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

  /// BC's waybill_trip From/To fields hold 20 characters. Route descriptions
  /// often exceed that and NAV then rejects the whole trip with "The length of
  /// the string is N, but it must be less than or equal to 20 characters" —
  /// the trip never appears. Route codes always fit, so the matching local
  /// route's code is sent; text with no matching route is trimmed to what BC
  /// accepts so a trip can never stay stuck on format alone.
  static String? bcRouteText(String? value, List<RouteModel> routes) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return value;

    for (final route in routes) {
      final code = (route.Code ?? '').trim();
      if (code.isEmpty) continue;
      if (_sameRouteText(code, text)) return code;
      if (_sameRouteText(route.Description, text)) return code;
    }

    return text.length <= _bcRouteMaxLength
        ? text
        : text.substring(0, _bcRouteMaxLength);
  }

  static const int _bcRouteMaxLength = 20;

  static bool _sameRouteText(String? a, String? b) =>
      (a ?? '').trim().toUpperCase() == (b ?? '').trim().toUpperCase();

  /// [bcRouteText] with the device's cached routes.
  Future<String?> _bcRouteText(String? value) async {
    if ((value ?? '').trim().isEmpty) return value;
    var routes = const <RouteModel>[];
    try {
      final rows =
          await db_Provider().getdata(RouteModel.table, RouteModel.columns);
      routes = rows.map(RouteModel.fromMap).toList();
    } catch (_) {
      // No local routes (e.g. a fresh install) — the text still gets trimmed.
    }
    return bcRouteText(value, routes);
  }

  /// Route description for [code] from the device's cached routes.
  Future<String?> _bcRouteDescription(String? code) async {
    final target = (code ?? '').trim().toUpperCase();
    if (target.isEmpty) return null;
    try {
      final rows =
          await db_Provider().getdata(RouteModel.table, RouteModel.columns);
      for (final r in rows.map(RouteModel.fromMap)) {
        if ((r.Code ?? '').trim().toUpperCase() == target) return r.Description;
      }
    } catch (_) {}
    return null;
  }

  /// Re-points trips saved against [oldKey] (the entry's local key before BC
  /// replaced it) at the waybill's BC key and entry number. Without this the
  /// trips keep a key that no longer exists, resolve to nothing, and can
  /// never sync (or show up under their entry).
  Future<void> _relinkTripsToNewKey(String oldKey, Waybill waybill) async {
    try {
      final update = <String, Object?>{
        WaybillTrip.col_Waybill_Key: waybill.Key,
      };
      if ((waybill.Entry_No ?? 0) > 0) {
        update[WaybillTrip.col_Weign_Bridge_id] = waybill.Entry_No;
      }
      await db_Provider().updatedata(
        WaybillTrip.table,
        update,
        '${WaybillTrip.col_Waybill_Key} = ?',
        [oldKey],
      );
    } catch (_) {
      // The repair sweep will adopt any trip left behind.
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
      // NAV caps From/To at 20 characters — send the route code so the trip
      // is not rejected for length.
      map['From'] = await _bcRouteText(trip.From);
      map['To'] = await _bcRouteText(trip.To);
      // NAV keeps the route description on the trip for reporting.
      map['Description'] =
          trip.Description ?? await _bcRouteDescription(trip.From);
      if (isTempKey(map['Key'] as String?)) {
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
        trip.dirty = false;
        await db.insert(WaybillTrip.table, trip);
      } else if ((result.Desc ?? '')
          .toLowerCase()
          .contains('already exists')) {
        // BC already has this trip — an earlier attempt reached NAV but the
        // app never recorded the result. Adopt BC's copy so the trip stops
        // retrying and later edits (close trip, expenses) update in place.
        await _adoptExistingTrip(trip);
      }
    } catch (_) {
      // Will be picked up by syncPendingWaybillTrips
    }
  }

  /// Finds the trip's row on BC (same entry + trip no) and adopts its key so
  /// the local row is marked as sent.
  Future<void> _adoptExistingTrip(WaybillTrip trip) async {
    try {
      final entryNo = trip.Weign_Bridge_id;
      if (entryNo == null || entryNo <= 0) return;

      final response = await _api
          .postdata('waybilltrips', json.encode({'waybillId': entryNo}));
      final result =
          Results<WaybillTrip>.fromJson(response.body, WaybillTrip.fromMap);
      if (result.Code != 0 || result.Contents == null) return;

      WaybillTrip? match;
      for (final t in result.Contents!) {
        if (t.Trip_No == trip.Trip_No) {
          match = t;
          break;
        }
      }
      if (match == null) return;

      final db = db_Provider();
      final oldKey = trip.Key;
      if (match.Key != null &&
          match.Key!.isNotEmpty &&
          match.Key != oldKey) {
        if (oldKey != null) {
          await db.deletedata(
              WaybillTrip.table, '${WaybillTrip.col_Key} = ?', [oldKey]);
        }
        trip.Key = match.Key;
      }
      trip.sent = true;
      trip.dirty = false;
      await db.insert(WaybillTrip.table, trip);
    } catch (_) {
      // Left pending — the next sync will try to adopt it again.
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
        '${WaybillTrip.col_sent} = 0 OR ${WaybillTrip.col_Dirty} = 1',
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

  /// Preference key holding the last successful trip sync time (UTC stamp).
  static const String _lastTripSyncKey = 'waybill_trip_last_sync';

  /// Pulls trips changed in BC after the stored sync time and merges them
  /// locally — this is how edits made on other devices (or in BC itself)
  /// arrive here. Local trips still waiting to push (sent = 0) are never
  /// overwritten. Advances the stored time on success.
  Future<int> pullModifiedTrips() async {
    try {
      if (!Get.isRegistered<MainController>()) return 0;
      final main = Get.find<MainController>();

      final nowUtc = DateTime.now().toUtc();
      var since = nowUtc.subtract(const Duration(hours: 24));
      final stored = await main.getPreference(_lastTripSyncKey);
      if (stored != null && stored.isNotEmpty) {
        // The stamp is written as UTC wall time with no zone suffix; parsing
        // it as local would shift the window by the device's offset (3h in
        // EAT) and re-fetch everything modified in that span each round.
        final parsed = DateTime.tryParse(
            stored.endsWith('Z') ? stored : '${stored}Z');
        if (parsed != null) since = parsed.toUtc();
      }

      String two(int v) => v.toString().padLeft(2, '0');
      String stamp(DateTime d) =>
          '${d.year}-${two(d.month)}-${two(d.day)}T${two(d.hour)}:${two(d.minute)}:${two(d.second)}';

      final request = Request(datefilter: stamp(since), size: 10000);
      final response =
          await _api.postdata('waybilltripsmodified', request.toJson());
      final result =
          Results<WaybillTrip>.fromJson(response.body, WaybillTrip.fromMap);
      if (result.Code != 0 || result.Contents == null) return 0;

      final db = db_Provider();
      var merged = 0;
      for (final server in result.Contents!) {
        final local = await _findLocalTrip(server, db);
        if (local == null) {
          server.sent = true;
          await db.insert(WaybillTrip.table, server);
          merged++;
          continue;
        }
        // Never overwrite local edits that are still waiting to push: dirty
        // trips or rows BC has not accepted yet.
        if (local.dirty || !local.sent) continue;

        server.sent = true;
        server.Waybill_Key = local.Waybill_Key;
        if (local.Key != null && local.Key != server.Key) {
          await db.deletedata(
              WaybillTrip.table, '${WaybillTrip.col_Key} = ?', [local.Key!]);
        }
        await db.insert(WaybillTrip.table, server);
        merged++;

        // Collapse duplicates: the same entry + trip number under another
        // (typically older) key. Only rows BC has accepted are removed —
        // never a local edit that is still waiting to push.
        if (server.Weign_Bridge_id != null && server.Trip_No != null) {
          final dupes = await db.getdata(
              WaybillTrip.table,
              WaybillTrip.columns,
              '${WaybillTrip.col_Weign_Bridge_id} = ? AND '
                  '${WaybillTrip.col_Trip_No} = ? AND '
                  '${WaybillTrip.col_Key} != ? AND '
                  '${WaybillTrip.col_sent} = 1 AND '
                  '(${WaybillTrip.col_Dirty} = 0 OR '
                  '${WaybillTrip.col_Dirty} IS NULL)',
              [
                server.Weign_Bridge_id!,
                server.Trip_No!,
                server.Key ?? '',
              ]);
          for (final dupe in dupes) {
            final dupeKey = dupe[WaybillTrip.col_Key];
            if (dupeKey is String && dupeKey.isNotEmpty) {
              await db.deletedata(
                  WaybillTrip.table, '${WaybillTrip.col_Key} = ?', [dupeKey]);
            }
          }
        }
      }

      // Two minutes of overlap so rows changed mid-sync are never missed;
      // merging is idempotent.
      await main.savePreference(_lastTripSyncKey,
          stamp(nowUtc.subtract(const Duration(minutes: 2))));
      return merged;
    } catch (_) {
      // Offline or BC rejected the read — the next sync tries again.
      return 0;
    }
  }

  /// Preference key holding the last successful waybill sync time (UTC stamp).
  static const String _lastWaybillSyncKey = 'waybill_last_sync';

  /// Pulls waybills changed in BC after the stored sync time and merges them
  /// locally — entries created or edited on other devices (or in BC itself)
  /// arrive here, whatever their date. Local rows still waiting to push are
  /// never overwritten. Advances the stored time on success.
  Future<int> pullModifiedWaybills() async {
    try {
      if (!Get.isRegistered<MainController>()) return 0;
      final main = Get.find<MainController>();

      final nowUtc = DateTime.now().toUtc();
      var since = nowUtc.subtract(const Duration(hours: 24));
      final stored = await main.getPreference(_lastWaybillSyncKey);
      if (stored != null && stored.isNotEmpty) {
        // Written as UTC wall time with no zone suffix — parse it as UTC so
        // the window is not shifted by the device's offset.
        final parsed = DateTime.tryParse(
            stored.endsWith('Z') ? stored : '${stored}Z');
        if (parsed != null) since = parsed.toUtc();
      }

      String two(int v) => v.toString().padLeft(2, '0');
      String stamp(DateTime d) =>
          '${d.year}-${two(d.month)}-${two(d.day)}T${two(d.hour)}:${two(d.minute)}:${two(d.second)}';

      final request = Request(datefilter: stamp(since), size: 10000);
      final response =
          await _api.postdata('waybillsmodified', request.toJson());
      final result = Results<Waybill>.fromJson(response.body, Waybill.fromMap);
      if (result.Code != 0 || result.Contents == null) return 0;

      var merged = 0;
      for (final server in result.Contents!) {
        if (await mergeServerWaybill(server)) merged++;
      }

      // Two minutes of overlap so rows changed mid-sync are never missed;
      // merging is idempotent.
      await main.savePreference(_lastWaybillSyncKey,
          stamp(nowUtc.subtract(const Duration(minutes: 2))));
      return merged;
    } catch (_) {
      // Offline or BC rejected the read — the next sync tries again.
      return 0;
    }
  }

  /// Local waybill row for [server] — matched by BC key, then by the
  /// vehicle + date business key (one entry per vehicle per day).
  Future<Waybill?> _findLocalWaybill(Waybill server, db_Provider db) async {
    try {
      if (server.Key != null && server.Key!.isNotEmpty) {
        final rows = await db.getdata(Waybill.table, Waybill.columns,
            '${Waybill.col_Key} = ?', [server.Key!]);
        if (rows.isNotEmpty) return Waybill.fromMap_db(rows.first);
      }
      if ((server.Vehicle_No ?? '').isNotEmpty && server.Date != null) {
        final rows = await db.getdata(
            Waybill.table,
            Waybill.columns,
            '${Waybill.col_Vehicle_No} = ? AND ${Waybill.col_Date} = ?',
            [server.Vehicle_No!, server.Date!.millisecondsSinceEpoch]);
        if (rows.isNotEmpty) return Waybill.fromMap_db(rows.first);
      }
    } catch (_) {
      // Fall through — treated as a new row.
    }
    return null;
  }

  /// Merges one server waybill into the local store. Never overwrites a
  /// local entry that is still waiting to push — its own push reconciles
  /// with BC later. When BC's key differs from the local one (a row that
  /// was re-keyed in BC), the stale-keyed duplicate is removed so only one
  /// row per vehicle + day survives. Returns true when a row was written.
  Future<bool> mergeServerWaybill(Waybill server) async {
    try {
      final db = db_Provider();
      final local = await _findLocalWaybill(server, db);
      if (local == null) {
        server.sent = (server.Entry_No ?? 0) > 0;
        await db.insert(Waybill.table, server);
        return true;
      }
      if (!local.sent) return false;

      server.sent = (server.Entry_No ?? 0) > 0;
      if (local.Key != null && local.Key != server.Key) {
        await db.deletedata(
            Waybill.table, '${Waybill.col_Key} = ?', [local.Key!]);
      }
      await db.insert(Waybill.table, server);

      // Collapse duplicates: another local row for the same vehicle + day
      // under a different (typically older) BC key. Only rows BC has
      // accepted are removed — never a local edit waiting to push.
      if ((server.Vehicle_No ?? '').isNotEmpty &&
          server.Date != null &&
          (server.Key ?? '').isNotEmpty) {
        final dupes = await db.getdata(
            Waybill.table,
            Waybill.columns,
            '${Waybill.col_Vehicle_No} = ? AND ${Waybill.col_Date} = ? AND '
                '${Waybill.col_Key} != ? AND ${Waybill.col_sent} = 1',
            [
              server.Vehicle_No!,
              server.Date!.millisecondsSinceEpoch,
              server.Key!,
            ]);
        for (final dupe in dupes) {
          final dupeKey = dupe[Waybill.col_Key];
          if (dupeKey is String && dupeKey.isNotEmpty) {
            await db.deletedata(
                Waybill.table, '${Waybill.col_Key} = ?', [dupeKey]);
          }
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Local row for [server] — matched by BC key, then entry + trip number.
  Future<WaybillTrip?> _findLocalTrip(
      WaybillTrip server, db_Provider db) async {
    try {
      if (server.Key != null && server.Key!.isNotEmpty) {
        final rows = await db.getdata(WaybillTrip.table, WaybillTrip.columns,
            '${WaybillTrip.col_Key} = ?', [server.Key!]);
        if (rows.isNotEmpty) return WaybillTrip.fromMap_db(rows.first);
      }
      if (server.Weign_Bridge_id != null && server.Trip_No != null) {
        final rows = await db.getdata(
            WaybillTrip.table,
            WaybillTrip.columns,
            '${WaybillTrip.col_Weign_Bridge_id} = ? AND '
                '${WaybillTrip.col_Trip_No} = ?',
            [server.Weign_Bridge_id!, server.Trip_No!]);
        if (rows.isNotEmpty) return WaybillTrip.fromMap_db(rows.first);
      }
    } catch (_) {}
    return null;
  }
}
