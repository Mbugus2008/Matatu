import 'package:flutter_test/flutter_test.dart';
import 'package:t_matatu/models/waybill/trip_comment.dart';

void main() {
  group('TripComment appendBlock', () {
    test('the first comment starts with its own stamp block', () {
      final text = TripComment.appendBlock(
        existing: null,
        text: 'Breakdown at Kencom',
        user: 'Paul',
        at: DateTime(2026, 10, 5, 18, 22),
      );
      expect(text, '[05/10/26 18:22 Paul]\nBreakdown at Kencom');
    });

    test('later comments append to the existing text with a blank line', () {
      final text = TripComment.appendBlock(
        existing: '[01/10/26 09:00 Paul]\nLate start',
        text: 'Police check on Ngong road',
        user: 'James',
        at: DateTime(2026, 10, 5, 18, 22),
      );
      expect(
        text,
        '[01/10/26 09:00 Paul]\nLate start\n\n'
        '[05/10/26 18:22 James]\nPolice check on Ngong road',
      );
    });

    test('trims stray whitespace around the new comment', () {
      final text = TripComment.appendBlock(
        existing: '  ',
        text: '  engine overheated  ',
        user: 'Paul',
        at: DateTime(2026, 10, 5, 8, 5),
      );
      expect(text, '[05/10/26 08:05 Paul]\nengine overheated');
    });
  });

  group('TripComment API mapping', () {
    test('toMap carries BC field names and the NAV date format', () {
      final comment = TripComment(
        Code: 'TC123',
        Trip_Id: 59,
        Comments: 'hello',
        User: 'Paul',
        Date_time: DateTime(2026, 10, 5, 18, 22, 0),
      );
      final map = comment.toMap();
      expect(map['Code'], 'TC123');
      expect(map['Trip_Id'], 59);
      expect(map['Comments'], 'hello');
      expect(map['User'], 'Paul');
      expect(map['Date_time'], '10/05/2026 18:22:00');
    });

    test('toMap never sends a null Trip_Id (BC rejects nulls)', () {
      final comment = TripComment(Comments: 'x');
      expect(comment.toMap()['Trip_Id'], 0);
      expect(comment.toMap()['Date_time'], isNotNull);
    });

    test('fromMap parses NAV and ISO dates and int trip ids', () {
      final nav = TripComment.fromMap({
        'Key': 'k;1;2;',
        'Code': 'TC1',
        'Trip_Id': 7,
        'Date_time': '10/05/2026 18:22:00',
      });
      expect(nav.Trip_Id, 7);
      expect(nav.Date_time, DateTime(2026, 10, 5, 18, 22, 0));

      final iso = TripComment.fromMap({
        'Trip_Id': 8,
        'Date_time': '2026-10-05T18:22:00',
      });
      expect(iso.Trip_Id, 8);
      expect(iso.Date_time, DateTime(2026, 10, 5, 18, 22, 0));
    });
  });

  group('TripComment local row', () {
    test('round trip keeps the sent flag and millisecond date', () {
      final comment = TripComment(
        Code: 'TC1',
        Trip_Id: 7,
        Comments: 'x',
        User: 'u',
        Date_time: DateTime(2026, 10, 5, 10, 0),
        sent: true,
      );
      final row = comment.toMap_fortable();
      expect(row['sent'], 1);
      expect(row['Date_time'],
          DateTime(2026, 10, 5, 10, 0).millisecondsSinceEpoch);

      final back = TripComment.fromMap_db(row);
      expect(back.Trip_Id, 7);
      expect(back.sent, true);
      expect(back.Date_time, DateTime(2026, 10, 5, 10, 0));
    });

    test('newCode uses the TC + milliseconds shape', () {
      expect(RegExp(r'^TC\d{13}$').hasMatch(TripComment.newCode()), true);
    });

    test('the local table is keyed by Code and tracks the sync flag', () {
      expect(TripComment.createtable.contains('primary key'), true);
      expect(TripComment.createtable.contains('sent'), true);
      expect(TripComment.createtable.contains(TripComment.table), true);
    });
  });
}
