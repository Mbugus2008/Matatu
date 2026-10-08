import 'package:flutter_test/flutter_test.dart';
import 'package:t_matatu/models/dashboard_cues.dart';

void main() {
  group('DashboardCues — parsing', () {
    final apiReply = <String, dynamic>{
      'Date': '2026-10-05T00:00:00',
      'Cash': 508040,
      'Mpesa': 270665,
      'Offload': 337095,
      'Management': 143950,
      'Savings': 94120,
      'Carwash': 8500,
      'DepotParking': 4400,
      'Expenses': 0,
      'Body': 10000,
      'Insurance': 8700,
      'NccParking': 28000,
      'Knh': 0,
      'SavingsCrew': 27480,
      'Security': 7600,
      'StatutorySundry': 27800,
      'Stones': 23400,
      'OffloadParking': 18000,
      'OnRoute': 2,
    };

    test('parses the API reply', () {
      final cues = DashboardCues.fromMap(apiReply);
      expect(cues.Date, DateTime(2026, 10, 5));
      expect(cues.Cash, 508040);
      expect(cues.Mpesa, 270665);
      expect(cues.Offload, 337095);
      expect(cues.Management, 143950);
      expect(cues.Savings, 94120);
      expect(cues.Carwash, 8500);
      expect(cues.DepotParking, 4400);
      expect(cues.Body, 10000);
      expect(cues.Insurance, 8700);
      expect(cues.NccParking, 28000);
      expect(cues.SavingsCrew, 27480);
      expect(cues.Security, 7600);
      expect(cues.StatutorySundry, 27800);
      expect(cues.Stones, 23400);
      expect(cues.OffloadParking, 18000);
      expect(cues.OnRoute, 2);
    });

    test('accepts decimal amounts', () {
      final cues = DashboardCues.fromMap({'Mpesa': 270665.26});
      expect(cues.Mpesa, closeTo(270665.26, 0.001));
    });

    test('missing fields fall back to zero', () {
      final cues = DashboardCues.fromMap(const {});
      expect(cues.Cash, 0);
      expect(cues.Mpesa, 0);
      expect(cues.OnRoute, 0);
      expect(cues.Date, isNull);
    });

    test('parses the hires/waybill/fuel operations figures', () {
      final cues = DashboardCues.fromMap(const {
        'HiresToday': 3,
        'HiresTodayAmount': 45000,
        'HiresPaidToday': 1,
        'HiresUnpaidToday': 2,
        'HiresByDay': [0, 1, 0, 2, 1, 0, 3],
        'WaybillsToday': 9,
        'WaybillTargetToday': 12280,
        'WaybillActualToday': 8000,
        'WaybillShortageToday': 4280,
        'WaybillTargetByDay': [1, 2, 3, 4, 5, 6, 7],
        'WaybillActualByDay': [1.5, 2.5, 3, 4, 5, 6, 6.5],
        'FuelToday': 25000,
        'FuelLitresToday': 120.5,
        'FuelByDay': [100, 200, 300, 400, 500, 600, 700],
      });
      expect(cues.HiresToday, 3);
      expect(cues.HiresTodayAmount, 45000);
      expect(cues.HiresPaidToday, 1);
      expect(cues.HiresToday - cues.HiresPaidToday, cues.HiresUnpaidToday);
      expect(cues.HiresByDay.length, 7);
      expect(cues.HiresByDay.last, 3);
      expect(cues.WaybillTargetByDay.last, 7);
      expect(cues.WaybillActualByDay.last, closeTo(6.5, 0.001));
      expect(cues.FuelLitresToday, closeTo(120.5, 0.001));
      expect(cues.FuelByDay.last, 700);
    });

    test('missing operations fields fall back to empty series', () {
      final cues = DashboardCues.fromMap(const {});
      expect(cues.HiresByDay, isEmpty);
      expect(cues.WaybillTargetByDay, isEmpty);
      expect(cues.WaybillActualByDay, isEmpty);
      expect(cues.FuelByDay, isEmpty);
      expect(cues.HiresToday, 0);
    });

    test('parses the cashiers summary', () {
      final cues = DashboardCues.fromMap(const {
        'Cash': 455490.5,
        'Cashiers': [
          {'Name': 'AGNES', 'Amount': 214060, 'Count': 121},
          {'Name': 'STANLEY', 'Amount': 144640.5, 'Count': 88},
          {'Name': 'ESTHER', 'Amount': 96790, 'Count': 51},
        ],
      });
      expect(cues.Cashiers.length, 3);
      expect(cues.Cashiers.first.Name, 'AGNES');
      expect(cues.Cashiers.first.Amount, 214060);
      expect(cues.Cashiers.first.Count, 121);
      expect(cues.Cashiers[1].Amount, closeTo(144640.5, 0.001));
      // The cashier amounts add up to the Cash cue.
      final sum = cues.Cashiers.fold<double>(0, (s, c) => s + c.Amount);
      expect(sum, closeTo(cues.Cash, 0.001));
    });

    test('missing cashiers falls back to an empty list', () {
      final cues = DashboardCues.fromMap(const {});
      expect(cues.Cashiers, isEmpty);
    });
  });
}
