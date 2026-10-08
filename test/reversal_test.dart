import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:t_matatu/models/Reversal.dart';

/// [Reversal.fromMap] parses rows exactly the way the API serializes them.
///
/// A whole-shilling amount arrives as a JSON int; the old `as double` cast
/// threw and silently killed every reversal sync — requests were never marked
/// sent (so they were re-pushed on every sync, overwriting an office approval
/// with the stale 'Open' copy) and approved reversals were never applied.
void main() {
  group('Reversal.fromMap (API payloads)', () {
    const payloadJson = '''
{"Key":"28;bsMAAAJ7/1IAVgAwADAAMAAwADQ=8;341685670;","No":"RV00004",
 "Receipt_No":"1791371589757196","Date":"10/07/2026 00:00:00","Status":3,
 "Created_By":"PAUL","Total_Amount":10,"Total_Trans":0,
 "Transction_Date":"10/07/2026 00:00:00","Agent":"PAUL",
 "Reason_for_Reversal":null,"Vehicle":"KBU515X","Account":"314",
 "Name":"JOSEPH GACHERU"}
''';

    Map<String, dynamic> payload() =>
        jsonDecode(payloadJson) as Map<String, dynamic>;

    test('parses a whole-shilling amount (JSON int) without crashing', () {
      final r = Reversal.fromMap(payload());
      expect(r.Total_Amount, 10.0);
      expect(r.Total_Trans, 0);
    });

    test('parses a decimal amount (JSON double)', () {
      final map = payload()..['Total_Amount'] = 10.5;
      expect(Reversal.fromMap(map).Total_Amount, 10.5);
    });

    test('parses the full row from BC', () {
      final r = Reversal.fromMap(payload());
      expect(r.Key, startsWith('28;'));
      expect(r.No, 'RV00004');
      expect(r.Receipt_No, '1791371589757196');
      expect(r.Status, STatus.Approved);
      expect(r.Vehicle, 'KBU515X');
      expect(r.Created_By, 'PAUL');
      expect(r.Date, DateTime(2026, 10, 7));
    });

    test('an unknown status value does not crash the parse', () {
      final map = payload()..['Status'] = 9;
      expect(Reversal.fromMap(map).Status, isNull);
    });

    test('missing fields stay null', () {
      final r = Reversal.fromMap(<String, dynamic>{'Receipt_No': 'x'});
      expect(r.Total_Amount, isNull);
      expect(r.Total_Trans, isNull);
      expect(r.Status, isNull);
    });
  });

  group('Reversal.fromMap_d (local rows)', () {
    test('accepts int values as well as doubles', () {
      final r = Reversal.fromMap_d(<String, dynamic>{
        'Receipt_No': 'x',
        'Status': 2,
        'Total_Amount': 10,
        'Total_Trans': 3,
        'Date': 0,
        'Transction_Date': 0,
      });
      expect(r.Total_Amount, 10.0);
      expect(r.Total_Trans, 3);
      expect(r.Status, STatus.Pending_Approval);
    });
  });
}
