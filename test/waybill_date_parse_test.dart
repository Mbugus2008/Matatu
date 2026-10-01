// Regression tests for waybill date parsing.
//
// The app POSTs ISO dates, but Business Central returns
// "MM/dd/yyyy HH:mm:ss" (and "01/01/0001 HH:mm:ss" for time-only fields), so a
// pull used to land with every date null.
import 'package:flutter_test/flutter_test.dart';
import 'package:t_matatu/models/waybill/waybill.dart';

void main() {
  group('Waybill.fromMap - dates from Business Central', () {
    test('parses the real payload for today\'s entry', () {
      final wb = Waybill.fromMap({
        'Key': '28;cMMAAAJ7/0sAQwBTADgAMAAzAEw=8;332655990;',
        'Vehicle_No': 'KCS803L',
        'Fleet_No': '716',
        'Driver': 'A988',
        'Conductor': 'B1571',
        'Date': '09/29/2026 00:00:00',
        'Start_Time': '01/01/0001 11:11:00',
        'Finish_Time': '01/01/0001 18:00:00',
        'Target_Revenue': 6770,
        'Actual_Revenue': 0,
        'Shortage': 6770,
        'Entry_No': 11,
        'Cash': 0,
        'Total_Expected': 0,
        'Total_Collected': 0,
      });

      expect(wb.Vehicle_No, 'KCS803L');
      expect(wb.Entry_No, 11);
      expect(wb.Target_Revenue, 6770);

      // The day itself must come through intact.
      expect(wb.Date, isNotNull);
      expect(wb.Date!.year, 2026);
      expect(wb.Date!.month, 9);
      expect(wb.Date!.day, 29);

      // Time-only fields keep their clock value (on a neutral day).
      expect(wb.Start_Time, isNotNull);
      expect(wb.Start_Time!.hour, 11);
      expect(wb.Start_Time!.minute, 11);
      expect(wb.Finish_Time!.hour, 18);
    });

    test('an unset date (NAV 01/01/0001) is null, not year 1', () {
      final wb = Waybill.fromMap({
        'Vehicle_No': 'KCS803L',
        'Date': '01/01/0001 00:00:00',
        'Finish_Time': '01/01/0001 00:00:00',
      });
      expect(wb.Date, isNull);
      expect(wb.Finish_Time, isNull);
    });

    test('still accepts ISO strings and epoch milliseconds', () {
      final iso = Waybill.fromMap({'Date': '2026-09-29T00:00:00.000'});
      expect(iso.Date, DateTime(2026, 9, 29));

      final epoch = DateTime(2026, 9, 29, 11, 11);
      final fromDb = Waybill.fromMap({
        'Date': epoch.millisecondsSinceEpoch,
        'Start_Time': epoch.millisecondsSinceEpoch,
      });
      expect(fromDb.Date, epoch);
      expect(fromDb.Start_Time, epoch);
    });

    test('missing and blank values stay null', () {
      final empty = Waybill.fromMap({'Date': null, 'Start_Time': ''});
      expect(empty.Date, isNull);
      expect(empty.Start_Time, isNull);
    });
  });

  group('WaybillTrip.fromMap - trip times', () {
    test('parses the real payload for a trip', () {
      final trip = WaybillTrip.fromMap({
        'Key': '12;csMAAACHBw==8;327428050;',
        'Weign_Bridge_id': 7,
        'Trip_No': 1,
        'From': 'KENCOM',
        'From_Time': '01/01/0001 14:52:00',
        'To': 'GPO',
        'To_Time': '01/01/0001 00:00:00',
        'Pax_No': 51,
        'Fare_Amount': 70,
        'Total': 3570,
        'Started_By': null,
        'Ended_by': null,
        'Amount_Received': null,
        'Expenses': 0,
        'Comments': null,
      });

      expect(trip.From, 'KENCOM');
      expect(trip.To, 'GPO');
      expect(trip.Pax_No, 51);
      expect(trip.Total, 3570);

      expect(trip.From_Time, isNotNull);
      expect(trip.From_Time!.hour, 14);
      expect(trip.From_Time!.minute, 52);

      // No arrival yet - BC sends the empty NAV date.
      expect(trip.To_Time, isNull);
    });
  });
}
