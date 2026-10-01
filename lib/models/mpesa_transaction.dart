// ignore_for_file: public_member_api_docs, sort_constructors_first
// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:t_matatu/models/Header.dart';
import 'package:t_matatu/models/mappings.dart';
import 'package:t_matatu/network/Apis.dart';
import 'package:t_matatu/network/request.dart';
import 'package:t_matatu/network/results/results.dart';
import 'package:t_matatu/providers/db.dart';

/// One M-Pesa transaction from BC's M-Pesa Transactions page (published as
/// the Mpesa_Transactions web service). The vehicle is carried in Loan_No and
/// the customer amount in Paid_In.
class MpesaTransaction extends Tomaps<MpesaTransaction> {
  String? Key;

  /// Receipt that settled this row — empty while the row is un-receipted.
  String? Receipt_No;
  DateTime? Transaction_Date;

  /// Customer money in — the figure the receipt sums.
  double? Paid_In;

  /// Vehicle number (BC stores it in the page's Loan_No field).
  String? Loan_No;
  String? Name;
  String? Phone;
  String? Status;
  bool? Processed;
  String? Receipted_By;
  DateTime? Receipted_At;
  String? Posted_ReceiptNo;

  MpesaTransaction({
    this.Key,
    this.Receipt_No,
    this.Transaction_Date,
    this.Paid_In,
    this.Loan_No,
    this.Name,
    this.Phone,
    this.Status,
    this.Processed,
    this.Receipted_By,
    this.Receipted_At,
    this.Posted_ReceiptNo,
  });

  /// True once OUR printed receipt has been stamped on the row.
  /// Posted_ReceiptNo / Receipted_At are the marking fields — Receipt_No
  /// itself holds the M-Pesa transaction code.
  bool get isReceipted =>
      (Posted_ReceiptNo ?? '').trim().isNotEmpty ||
      (Receipted_At != null && Receipted_At!.year > 1);

  @override
  Map<String, dynamic> toMap() => <String, dynamic>{
        'Key': Key,
        'Receipt_No': Receipt_No,
        'Transaction_Date': Transaction_Date?.toIso8601String(),
        'Paid_In': Paid_In,
        'Loan_No': Loan_No,
        'Name': Name,
        'Phone': Phone,
        'Status': Status,
        'Processed': Processed,
        'Receipted_By': Receipted_By,
        'Receipted_At': Receipted_At?.toIso8601String(),
        'Posted_ReceiptNo': Posted_ReceiptNo,
      };

  /// Minimal update payload for marking this row as receipted. Only the
  /// fields being changed are sent, so BC leaves the rest untouched.
  Map<String, dynamic> toMarkMap({required String receiptNo, String? agent}) {
    final map = <String, dynamic>{
      'Key': Key,
      'Posted_ReceiptNo': receiptNo,
      'Receipted_At': DateTime.now().toIso8601String(),
    };
    if ((agent ?? '').trim().isNotEmpty) map['Receipted_By'] = agent;
    return map;
  }

  @override
  MpesaTransaction fromMap_table(Map<String, dynamic> map) =>
      MpesaTransaction.fromMap(map);

  static MpesaTransaction fromMap(Map<String, dynamic> map) =>
      MpesaTransaction(
        Key: map['Key'] as String?,
        Receipt_No: map['Receipt_No'] as String?,
        Transaction_Date: _parseDate(map['Transaction_Date']),
        Paid_In: (map['Paid_In'] as num?)?.toDouble(),
        Loan_No: map['Loan_No'] as String?,
        Name: map['Name'] as String?,
        Phone: map['Phone'] as String?,
        Status: map['Status']?.toString(),
        Processed: _parseBool(map['Processed']),
        Receipted_By: map['Receipted_By'] as String?,
        Receipted_At: _parseDate(map['Receipted_At']),
        Posted_ReceiptNo: map['Posted_ReceiptNo'] as String?,
      );

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value.toString().trim().toLowerCase();
    if (text.isEmpty) return null;
    return text == 'true' || text == 'yes' || text == '1';
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    final iso = DateTime.tryParse(text);
    if (iso != null) return iso;
    // NAV serialises dates with en-US culture.
    for (final pattern in const [
      'MM/dd/yyyy HH:mm:ss',
      'MM/dd/yyyy',
    ]) {
      try {
        return DateFormat(pattern).parseStrict(text);
      } catch (_) {}
    }
    return null;
  }
}

/// API helpers for the M-Pesa transactions feed.
class MpesaTransactionService {
  final ApiClient _api = ApiClient();

  /// Start of today — the fallback cutoff when no receipt exists yet.
  static DateTime startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Transactions for a vehicle — matched by its till ([paybill]) — with
  /// Transaction_Date after [since] (defaults to the start of today).
  Future<List<MpesaTransaction>> fetchSince({
    String? vehicleNo,
    String? paybill,
    DateTime? since,
  }) async {
    final target = (vehicleNo ?? '').trim().toUpperCase();
    final till = (paybill ?? '').trim();
    if (target.isEmpty && till.isEmpty) return [];
    try {
      final request = Request(
        vehicle: target.isEmpty ? null : target,
        paybill: till.isEmpty ? null : till,
        datefilter: _stampIso(since ?? startOfToday()),
        size: 1000,
      );
      final response =
          await _api.postdata('getmtransactions', request.toJson());
      final result = Results<MpesaTransaction>.fromJson(
          response.body, MpesaTransaction.fromMap);
      if (result.Code == 0 && result.Contents != null) {
        return result.Contents!;
      }
    } catch (_) {}
    return [];
  }

  /// Paid M-Pesa for the vehicle whose till is [paybill], since its last
  /// printed receipt — only un-receipted transactions count. Returns null
  /// when the till is unknown or the feed is unreachable — callers fall back
  /// to the daily-collection figure so the receipt still works offline.
  Future<double?> paidSinceLastReceipt({
    required String vehicleNo,
    String? paybill,
  }) async {
    final till = (paybill ?? '').trim();
    // Without the till, fleet-wide transactions cannot be told apart — the
    // daily-collection fallback is safer than a wrong sum.
    if (till.isEmpty) return null;
    final since =
        await lastReceiptTime(vehicleNo) ?? startOfToday();
    try {
      final request = Request(
        paybill: till,
        datefilter: _stampIso(since),
        size: 1000,
      );
      final response =
          await _api.postdata('getmtransactions', request.toJson());
      final result = Results<MpesaTransaction>.fromJson(
          response.body, MpesaTransaction.fromMap);
      if (result.Code != 0 || result.Contents == null) return null;
      // Receipted rows are skipped: the receipt that settled them already
      // took their money into account.
      return totalOf(result.Contents!.where((t) => !t.isReceipted));
    } catch (_) {
      return null;
    }
  }

  /// Time of the most recent receipt printed for [vehicleNo], read from the
  /// local receipt headers (Receipt_No is a microsecond timestamp). Pass
  /// [excludeReceiptNo] to look past the receipt currently being printed.
  Future<DateTime?> lastReceiptTime(
    String vehicleNo, {
    String? excludeReceiptNo,
  }) async {
    try {
      final target = vehicleNo.trim();
      if (target.isEmpty) return null;
      final rows = await db_Provider().getdata(
        Header.table,
        Header.columns,
        '${Header.col_Vehicle} = ?',
        [target],
      );
      DateTime? best;
      for (final row in rows) {
        final receipt = row[Header.col_Receipt_No] as String?;
        if (receipt == null ||
            receipt.isEmpty ||
            receipt == excludeReceiptNo) {
          continue;
        }
        final micros = int.tryParse(receipt);
        if (micros == null || micros < 1000000000000) continue;
        final when = DateTime.fromMicrosecondsSinceEpoch(micros);
        if (best == null || when.isAfter(best)) best = when;
      }
      return best;
    } catch (_) {
      return null;
    }
  }

  /// Pushes [transactions] back to BC with Receipt_No = [receiptNo] — the
  /// "update those M-Pesa transactions" step run after a receipt is printed,
  /// so the rows are no longer counted by the next receipt. Returns how many
  /// BC accepted.
  Future<int> markReceipted(
    List<MpesaTransaction> transactions, {
    required String receiptNo,
    String? agent,
  }) async {
    if (receiptNo.trim().isEmpty) return 0;
    var updated = 0;
    for (final transaction in transactions) {
      if ((transaction.Key ?? '').isEmpty) continue;
      if (transaction.isReceipted) continue;
      try {
        final response = await _api.postdata(
          'setmpesatransaction',
          json.encode(
              transaction.toMarkMap(receiptNo: receiptNo, agent: agent)),
        );
        final result = Results<MpesaTransaction>.fromJson(
            response.body, MpesaTransaction.fromMap);
        if (result.Code == 0) updated++;
      } catch (_) {
        // Retried implicitly: the row stays un-receipted in the feed.
      }
    }
    return updated;
  }

  /// Sum of [transactions]' Paid_In amounts (null amounts count as 0).
  static double totalOf(Iterable<MpesaTransaction> transactions) {
    var total = 0.0;
    for (final transaction in transactions) {
      total += transaction.Paid_In ?? 0;
    }
    return total;
  }

  static String _stampIso(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}'
        'T${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
  }
}
