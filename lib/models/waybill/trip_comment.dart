// ignore_for_file: non_constant_identifier_names, camel_case_types

import 'dart:convert';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:t_matatu/models/Utils/util.dart';
import 'package:t_matatu/models/mappings.dart';
import 'package:t_matatu/network/Apis.dart';
import 'package:t_matatu/network/results/results.dart';
import 'package:t_matatu/providers/db.dart';

/// A comment recorded against a trip (BC page "TripComments").
///
/// The BC page is keyed by **Trip_Id** — one comment record per trip — so the
/// device keeps at most one row per trip too and appends new comments to its
/// text (see [appendBlock]). Comments are captured offline first ([sent] =
/// false) and pushed to BC in the background; a push never overwrites another
/// device's row without going through the same append path here.
class TripComment
    implements mapping, Tomaps<TripComment>, AbsDbUpdates, data<TripComment> {
  String? Key;
  String? Code;

  /// The trip's auto-incrementing trip number ("Trip #N" shown to the user).
  int? Trip_Id;
  String? Comments;

  /// Agent code of whoever added the latest comment.
  String? User;
  DateTime? Date_time;

  /// False while the comment only exists on this device. Set to true once BC
  /// has accepted it.
  bool sent = false;

  TripComment({
    this.Key,
    this.Code,
    this.Trip_Id,
    this.Comments,
    this.User,
    this.Date_time,
    this.sent = false,
  });

  /// Appends [text] to the existing comment text as a stamped block, so each
  /// addition keeps who wrote it and when even though BC stores a single
  /// comment field per trip.
  static String appendBlock({
    String? existing,
    required String text,
    required String user,
    required DateTime at,
  }) {
    final stamp = DateFormat('dd/MM/yy HH:mm').format(at);
    final entry = '[$stamp ${user.trim()}]'.trimRight() + '\n' + text.trim();
    final prev = (existing ?? '').trim();
    return prev.isEmpty ? entry : '$prev\n\n$entry';
  }

  factory TripComment.fromMap(Map<String, dynamic> map) {
    return TripComment(
      Key: map['Key']?.toString(),
      Code: map['Code']?.toString(),
      Trip_Id: map['Trip_Id'] != null ? (map['Trip_Id'] as num).toInt() : null,
      Comments: map['Comments']?.toString(),
      User: map['User']?.toString(),
      Date_time: _parseDate(map['Date_time']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'Key': Key,
      'Code': Code,
      // BC's WCF model is non-nullable — null would be rejected (HTTP 400).
      'Trip_Id': Trip_Id ?? 0,
      'Comments': Comments,
      'User': User,
      'Date_time': formattedDateTime.format((Date_time ?? DateTime.now())),
    };
  }

  factory TripComment.fromJson(String source) =>
      TripComment.fromMap(json.decode(source) as Map<String, dynamic>);

  String toJson() => json.encode(toMap());

  @override
  TripComment fromMap_table(Map<String, dynamic> map) {
    return TripComment.fromMap_db(map);
  }

  @override
  Map<String, dynamic> toMap_fortable() {
    return {
      'Key': Key,
      'Code': Code,
      'Trip_Id': Trip_Id,
      'Comments': Comments,
      'User': User,
      'Date_time': Date_time?.millisecondsSinceEpoch,
      'sent': sent ? 1 : 0,
    };
  }

  factory TripComment.fromMap_db(Map<String, dynamic> map) {
    return TripComment(
      Key: map['Key']?.toString(),
      Code: map['Code']?.toString(),
      Trip_Id: map['Trip_Id'] != null ? (map['Trip_Id'] as num).toInt() : null,
      Comments: map['Comments']?.toString(),
      User: map['User']?.toString(),
      Date_time: _parseDate(map['Date_time']),
      sent: (map['sent'] ?? 0) == 1,
    );
  }

  /// Dates reach this model in three shapes: int milliseconds from the local
  /// table, NAV's MM/dd/yyyy HH:mm:ss from the API, and ISO-8601 from JSON.
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return DateFormat('MM/dd/yyyy HH:mm:ss', 'en_US').tryParse(text) ??
        DateTime.tryParse(text);
  }

  static const String table = 'tripcomments';
  static const String col_Key = 'Key';
  static const String col_Code = 'Code';
  static const String col_Trip_Id = 'Trip_Id';
  static const String col_Comments = 'Comments';
  static const String col_User = 'User';
  static const String col_Date_time = 'Date_time';
  static const String col_sent = 'sent';

  static const List<String> columns = [
    col_Key,
    col_Code,
    col_Trip_Id,
    col_Comments,
    col_User,
    col_Date_time,
    col_sent,
  ];

  static const String createtable = '''create table IF NOT EXISTS $table (
$col_Key text,
$col_Code text primary key,
$col_Trip_Id int,
$col_Comments text,
$col_User text,
$col_Date_time int,
$col_sent integer DEFAULT 0
)
''';

  @override
  List<DbUpdate>? updates() {
    return [
      DbUpdate(version: 19, updates: [createtable])
    ];
  }

  @override
  Future<List<TripComment>> getall() async {
    final rows = await Get.find<db_Provider>()
        .getalltrans(TripComment.columns, TripComment.table);
    return rows.map(TripComment.fromMap_db).toList();
  }

  // ─── Local-first sync ───

  /// BC keeps the Code the device generates (TC + milliseconds), so a comment
  /// captured offline keeps the same identity once the page accepts it.
  static String newCode() => 'TC${DateTime.now().millisecondsSinceEpoch}';

  /// Rows that only exist on this device.
  static Future<List<TripComment>> pending() async {
    final rows = await Get.find<db_Provider>()
        .getdata(table, columns, '$col_sent = 0 OR $col_sent IS NULL');
    return rows.map(TripComment.fromMap_db).toList();
  }

  /// The comment record for one trip, or null when it has none yet. BC allows
  /// a single record per trip, so the newest local row wins.
  static Future<TripComment?> forTrip(int? tripNo) async {
    if (tripNo == null || tripNo <= 0) return null;
    final rows = await Get.find<db_Provider>()
        .getdata(table, columns, '$col_Trip_Id = ?', [tripNo]);
    if (rows.isEmpty) return null;
    final list = rows.map(TripComment.fromMap_db).toList()
      ..sort((a, b) => (a.Date_time ?? DateTime(1970))
          .compareTo(b.Date_time ?? DateTime(1970)));
    return list.last;
  }

  /// The comment records for several trips at once, keyed by Trip_Id — used
  /// by the receipt page's trips popup.
  static Future<Map<int, TripComment>> forTrips(List<int> tripNos) async {
    final wanted = tripNos.where((n) => n > 0).toSet();
    if (wanted.isEmpty) return {};
    try {
      final rows = await Get.find<db_Provider>().getdata(table, columns);
      final result = <int, TripComment>{};
      for (final row in rows.map(TripComment.fromMap_db)) {
        final id = row.Trip_Id ?? 0;
        if (!wanted.contains(id)) continue;
        final prev = result[id];
        if (prev == null ||
            (row.Date_time ?? DateTime(1970))
                .isAfter(prev.Date_time ?? DateTime(1970))) {
          result[id] = row;
        }
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  Future<TripComment> saveLocal() async {
    Code ??= newCode();
    await Get.find<db_Provider>().insert(table, this);
    return this;
  }

  static Future<void> deleteLocal(String? code) async {
    if (code == null) return;
    await Get.find<db_Provider>().deletedata(table, '$col_Code = ?', [code]);
  }

  /// Resends everything pending. Called after sign-in and after every save;
  /// failures are swallowed so a dead network never blocks the caller.
  static Future<void> flushPending() async {
    try {
      await postPending();
    } catch (_) {
      // Offline or page unavailable: rows stay pending for the next try.
    }
  }

  /// Posts everything still pending. Returns how many rows BC accepted.
  static Future<int> postPending() async => postRows(await pending());

  /// Sends [rows] in one request through settripcommentsbatch. Rows BC
  /// rejected stay unsynced, so a partial success is reported rather than
  /// thrown.
  static Future<int> postRows(List<TripComment> rows) async {
    if (rows.isEmpty) return 0;
    final payload = json.encode(rows.map((r) => r.toMap()).toList());
    final response =
        await ApiClient().postdata('settripcommentsbatch', payload);
    if (response.statusCode != 200) {
      throw Exception('Server error ${response.statusCode}');
    }
    final results =
        Results<TripComment>.fromJson(response.body, TripComment.fromMap);
    if (results.Code != 0) {
      throw Exception(results.Desc ?? 'Post failed');
    }
    var synced = 0;
    for (final server in results.Contents ?? <TripComment>[]) {
      final local = _matchLocal(rows, server);
      if (local == null) continue;
      if (server.Code != null && server.Code != local.Code) {
        // BC renumbered the entry: move the local row onto the new code
        // instead of leaving a duplicate behind.
        await deleteLocal(local.Code);
        local.Code = server.Code;
      }
      local.Key = server.Key ?? local.Key;
      local.sent = true;
      await Get.find<db_Provider>().insert(table, local);
      synced++;
    }
    return synced;
  }

  static TripComment? _matchLocal(List<TripComment> rows, TripComment server) {
    for (final row in rows) {
      if (server.Code != null && row.Code == server.Code) return row;
      if (server.Key != null && row.Key == server.Key) return row;
      if ((server.Trip_Id ?? 0) > 0 && row.Trip_Id == server.Trip_Id) {
        return row;
      }
    }
    return null;
  }

  @override
  String toString() {
    return 'TripComment(Key: $Key, Code: $Code, Trip_Id: $Trip_Id, Comments: $Comments, User: $User, Date_time: $Date_time, sent: $sent)';
  }
}
