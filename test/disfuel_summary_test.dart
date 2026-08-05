import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:t_matatu/controllers/main.dart';
import 'package:t_matatu/pages/disfuel_summary.dart';
import 'package:t_matatu/providers/AppConfig.dart';
import 'package:t_matatu/providers/logger.dart';

// ─── Helpers ────────────────────────────────────────────

void _setupGetX() {
  Get.testMode = true;
  if (!Get.isRegistered<LoggerService>()) {
    Get.put(LoggerService(), permanent: true);
  }
  final mc = MainController();
  mc.config?.value = AppConfig(
    apiBaseUrl: 'http://localhost/api/',
    clientId: 'CITYHOPPER',
    clientName: 'CityHoppa',
    logo: 'assets/logo.png',
  );
  Get.put<MainController>(mc, permanent: true);
}

void _teardownGetX() {
  Get.reset();
  Get.testMode = false;
}

DisFuelSummary _sample({String? key, DateTime? date}) => DisFuelSummary(
      Key: key ?? '12;dMMAAAAu3ZAW8;308240320;',
      Date: date ?? DateTime(2026, 7, 28),
      Total_Vehicles: 25,
      Total_Fuel_ltrs: 500.5,
      Total_Fuels_Amount: 75000,
      Total_Paid: 70000,
      Total_Mileage: 1200,
      Total_Fuel_Arrears: 5000,
    );

const _sampleJson = '''
{
  "Code": 0,
  "Desc": "Successful",
  "Contents": [
    {
      "Key": "12;dMMAAAAu3ZAW8;308240320;",
      "Date": "07/28/2026 00:00:00",
      "Total_Vehicles": 25,
      "Total_Fuel_ltrs": 500.5,
      "Total_Fuels_Amount": 75000,
      "Total_Paid": 70000,
      "Total_Mileage": 1200,
      "Total_Fuel_Arrears": 5000
    },
    {
      "Key": "12;dMMAAAAu55AW8;308240360;",
      "Date": "07/31/2026 00:00:00",
      "Total_Vehicles": 30,
      "Total_Fuel_ltrs": 620.0,
      "Total_Fuels_Amount": 93000,
      "Total_Paid": 90000,
      "Total_Mileage": 1500,
      "Total_Fuel_Arrears": 3000
    }
  ]
}''';

void main() {
  // ═══════════════════════════════════════════════════════
  // MODEL TESTS
  // ═══════════════════════════════════════════════════════

  group('DisFuelSummary model', () {
    test('create with all fields', () {
      final d = _sample();
      expect(d.Key, '12;dMMAAAAu3ZAW8;308240320;');
      expect(d.Date, DateTime(2026, 7, 28));
      expect(d.Total_Vehicles, 25);
      expect(d.Total_Fuel_ltrs, 500.5);
      expect(d.Total_Fuels_Amount, 75000);
      expect(d.Total_Paid, 70000);
      expect(d.Total_Mileage, 1200);
      expect(d.Total_Fuel_Arrears, 5000);
      expect(d.sent, false);
    });

    test('toMap produces correct keys', () {
      final d = _sample();
      final map = d.toMap();
      expect(map['Key'], '12;dMMAAAAu3ZAW8;308240320;');
      expect(map['Total_Vehicles'], 25);
      expect(map['Total_Fuel_ltrs'], 500.5);
      expect(map['Total_Fuels_Amount'], 75000);
    });

    test('fromMap parses MM/dd/yyyy date format', () {
      final map = <String, dynamic>{
        'Key': 'K1',
        'Date': '07/31/2026 00:00:00',
        'Total_Vehicles': 10,
        'Total_Fuel_ltrs': 100.0,
        'Total_Fuels_Amount': 15000.0,
        'Total_Paid': 14000.0,
        'Total_Mileage': 500.0,
        'Total_Fuel_Arrears': 1000.0,
      };
      final d = DisFuelSummary.fromMap(map);
      expect(d.Date, DateTime(2026, 7, 31));
    });

    test('fromMap handles null date gracefully', () {
      final map = <String, dynamic>{
        'Key': 'K1',
        'Date': null,
        'Total_Vehicles': 10,
      };
      final d = DisFuelSummary.fromMap(map);
      expect(d.Date, isNull);
    });

    test('toMap_fortable converts Date to millisecondsSinceEpoch', () {
      final d = _sample(date: DateTime(2026, 7, 31));
      final map = d.toMap_fortable();
      final expectedMs = DateTime(2026, 7, 31).millisecondsSinceEpoch;
      expect(map['Date'], expectedMs);
    });

    test('fromMap_db reads sent flag', () {
      final map = <String, dynamic>{
        'Key': 'K1',
        'Date': DateTime(2026, 7, 31).millisecondsSinceEpoch,
        'Total_Vehicles': 10,
        'Total_Fuel_ltrs': 100.0,
        'Total_Fuels_Amount': 15000.0,
        'Total_Paid': 14000.0,
        'Total_Mileage': 500.0,
        'Total_Fuel_Arrears': 1000.0,
        'sent': 1,
      };
      final d = DisFuelSummary.fromMap_db(map);
      expect(d.sent, true);
    });

    test('fromMap_db defaults sent to false', () {
      final map = <String, dynamic>{
        'Key': 'K1',
        'Date': DateTime(2026, 7, 31).millisecondsSinceEpoch,
        'Total_Vehicles': 10,
        'Total_Fuel_ltrs': 100.0,
        'Total_Fuels_Amount': 15000.0,
        'Total_Paid': 14000.0,
        'Total_Mileage': 500.0,
        'Total_Fuel_Arrears': 1000.0,
        'sent': 0,
      };
      final d = DisFuelSummary.fromMap_db(map);
      expect(d.sent, false);
    });

    test('toJson / fromMap round-trip', () {
      final d = _sample();
      final json = d.toJson();
      final restored =
          DisFuelSummary.fromMap(jsonDecode(json) as Map<String, dynamic>);
      expect(restored.Key, d.Key);
      expect(restored.Total_Vehicles, d.Total_Vehicles);
      expect(restored.Total_Fuel_ltrs, d.Total_Fuel_ltrs);
    });

    test('table name is correct', () {
      expect(DisFuelSummary.table, 'disfuel_summary');
    });

    test('createtable SQL contains all columns', () {
      final sql = DisFuelSummary.createtable;
      expect(sql, contains('CREATE TABLE IF NOT EXISTS disfuel_summary'));
      expect(sql, contains('Key TEXT PRIMARY KEY'));
      expect(sql, contains('Date INTEGER'));
      expect(sql, contains('Total_Vehicles INTEGER'));
      expect(sql, contains('Total_Fuel_ltrs REAL'));
      expect(sql, contains('Total_Fuels_Amount REAL'));
      expect(sql, contains('Total_Paid REAL'));
      expect(sql, contains('Total_Mileage REAL'));
      expect(sql, contains('Total_Fuel_Arrears REAL'));
      expect(sql, contains('sent INTEGER DEFAULT 0'));
    });

    test('columns list matches table schema', () {
      expect(DisFuelSummary.columns, [
        'Key',
        'Date',
        'Total_Vehicles',
        'Total_Fuel_ltrs',
        'Total_Fuels_Amount',
        'Total_Paid',
        'Total_Mileage',
        'Total_Fuel_Arrears',
        'sent',
      ]);
    });
  });

  // ═══════════════════════════════════════════════════════
  // RESULTS PARSING TESTS
  // ═══════════════════════════════════════════════════════

  group('ResultsDisFuel', () {
    test('parses successful response with records', () {
      final result = ResultsDisFuel.fromJson(_sampleJson);
      expect(result.Code, 0);
      expect(result.Desc, 'Successful');
      expect(result.Contents, isNotNull);
      expect(result.Contents!.length, 2);
    });

    test('parses first record correctly', () {
      final result = ResultsDisFuel.fromJson(_sampleJson);
      final first = result.Contents!.first;
      expect(first.Key, '12;dMMAAAAu3ZAW8;308240320;');
      expect(first.Date, DateTime(2026, 7, 28));
      expect(first.Total_Vehicles, 25);
    });

    test('parses second record correctly', () {
      final result = ResultsDisFuel.fromJson(_sampleJson);
      final second = result.Contents!.last;
      expect(second.Key, '12;dMMAAAAu55AW8;308240360;');
      expect(second.Date, DateTime(2026, 7, 31));
      expect(second.Total_Vehicles, 30);
    });

    test('handles empty Contents', () {
      const json = '{"Code": 0, "Desc": "Successful", "Contents": []}';
      final result = ResultsDisFuel.fromJson(json);
      expect(result.Contents, isEmpty);
    });

    test('handles null Contents', () {
      const json = '{"Code": -1, "Desc": "Error", "Contents": null}';
      final result = ResultsDisFuel.fromJson(json);
      expect(result.Contents, isNull);
      expect(result.Code, -1);
    });
  });

  // ═══════════════════════════════════════════════════════
  // WIDGET TESTS
  // ═══════════════════════════════════════════════════════

  group('DisFuelSummaryPage widget', () {
    setUp(_setupGetX);
    tearDown(_teardownGetX);

    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(home: DisFuelSummaryPage()),
      );
      await tester.pump();
      // Page should render its date bar
      expect(find.byType(DisFuelSummaryPage), findsOneWidget);
    });

    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(home: DisFuelSummaryPage()),
      );
      // While loading, shows CircularProgressIndicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows calendar icon in date bar', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(home: DisFuelSummaryPage()),
      );
      await tester.pump();
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('shows refresh button', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(home: DisFuelSummaryPage()),
      );
      await tester.pump();
      expect(find.text('Refresh'), findsOneWidget);
    });

    testWidgets('shows empty state when no data', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(home: DisFuelSummaryPage()),
      );
      // Let loading finish — will hit catch and show empty state
      await tester.pumpAndSettle(const Duration(seconds: 5));
      // Should show empty state text
      expect(find.text('No summaries yet'), findsOneWidget);
    });
  });
}
