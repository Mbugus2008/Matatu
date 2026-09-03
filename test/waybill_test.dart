import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:t_matatu/controllers/main.dart';
import 'package:t_matatu/controllers/waybill_controller.dart';
import 'package:t_matatu/models/waybill/waybill.dart';
import 'package:t_matatu/network/results/results.dart';
import 'package:t_matatu/pages/waybill/trip_form.dart';
import 'package:t_matatu/pages/waybill/trip_list.dart';
import 'package:t_matatu/pages/waybill/waybill_form.dart';
import 'package:t_matatu/pages/waybill/waybill_list.dart';
import 'package:t_matatu/providers/AppConfig.dart';
import 'package:t_matatu/providers/logger.dart';

// ─── Helpers ────────────────────────────────────────────

/// Shared setUp for all test groups that need GetX
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

// ─── Helpers ────────────────────────────────────────────

Waybill _sampleWaybill({String key = ''}) => Waybill(
      Key: key.isEmpty ? null : key,
      Vehicle_No: 'KAA 001A',
      Fleet_No: 'F01',
      Driver: 'John Doe',
      Conductor: 'Jane Smith',
      Date: DateTime(2026, 7, 28),
      Start_Time: DateTime(2026, 7, 28, 8, 0),
      Finish_Time: DateTime(2026, 7, 28, 18, 0),
      Target_Revenue: 5000,
      Actual_Revenue: 4800,
      Shortage: 200,
      Cash: 4800,
      sent: false,
    );

WaybillTrip _sampleTrip({String key = ''}) => WaybillTrip(
      Key: key.isEmpty ? null : key,
      Weign_Bridge_id: 1,
      Trip_No: 1,
      From: 'Nairobi',
      From_Time: DateTime(2026, 7, 28, 8, 0),
      To: 'Mombasa',
      To_Time: DateTime(2026, 7, 28, 14, 0),
      Pax_No: 32,
      Fare_Amount: 500,
      Total: 16000,
      Started_By: 'Agent A',
      Amount_Received: 'CASH',
      Expenses: 2000,
      Comments: 'Test trip',
    );

void main() {
  // ═══════════════════════════════════════════════════════
  // MODEL TESTS
  // ═══════════════════════════════════════════════════════

  group('Waybill model — CRUD', () {
    test('create new Waybill with defaults', () {
      final wb = Waybill();
      expect(wb.Key, isNull);
      expect(wb.sent, false);
      expect(wb.Target_Revenue, isNull);
    });

    test('create Waybill with all fields', () {
      final wb = _sampleWaybill();
      expect(wb.Vehicle_No, 'KAA 001A');
      expect(wb.Fleet_No, 'F01');
      expect(wb.Driver, 'John Doe');
      expect(wb.Conductor, 'Jane Smith');
      expect(wb.Target_Revenue, 5000);
      expect(wb.Actual_Revenue, 4800);
      expect(wb.Shortage, 200);
      expect(wb.Cash, 4800);
      expect(wb.sent, false);
    });

    test('edit Waybill fields', () {
      final wb = _sampleWaybill();
      wb.Actual_Revenue = 5200;
      wb.Shortage = -200;
      wb.Cash = 5200;
      wb.sent = true;
      expect(wb.Actual_Revenue, 5200);
      expect(wb.Shortage, -200);
      expect(wb.Cash, 5200);
      expect(wb.sent, true);
    });

    test('toMap produces correct API format', () {
      final wb = _sampleWaybill();
      final map = wb.toMap();
      expect(map['Vehicle_No'], 'KAA 001A');
      expect(map['Fleet_No'], 'F01');
      expect(map['Target_Revenue'], 5000);
      expect(map['Actual_Revenue'], 4800);
      expect(map['Shortage'], 200);
      expect(map['Cash'], 4800);
      expect(map['Date'], contains('2026-07-28'));
    });

    test('fromMap roundtrip preserves values', () {
      final original = _sampleWaybill(key: 'KEY123');
      final map = original.toMap();
      final restored = Waybill.fromMap(map);
      expect(restored.Vehicle_No, original.Vehicle_No);
      expect(restored.Fleet_No, original.Fleet_No);
      expect(restored.Driver, original.Driver);
      expect(restored.Conductor, original.Conductor);
      expect(restored.Target_Revenue, original.Target_Revenue);
      expect(restored.Actual_Revenue, original.Actual_Revenue);
      expect(restored.Shortage, original.Shortage);
      expect(restored.Cash, original.Cash);
    });

    test('toMap_fortable stores Date as milliseconds', () {
      final wb = _sampleWaybill();
      final map = wb.toMap_fortable();
      expect(map['Date'], isA<int>());
      expect(map['sent'], 0); // false → 0
      wb.sent = true;
      expect(wb.toMap_fortable()['sent'], 1); // true → 1
    });

    test('fromMap_db restores Date from milliseconds', () {
      final wb = _sampleWaybill();
      final dbMap = wb.toMap_fortable();
      final restored = Waybill.fromMap_db(dbMap);
      expect(restored.Date?.year, 2026);
      expect(restored.Date?.month, 7);
      expect(restored.Date?.day, 28);
      expect(restored.sent, false);
    });

    test('shortage calculation: target - actual', () {
      final wb = _sampleWaybill();
      wb.Target_Revenue = 5000;
      wb.Actual_Revenue = 4200;
      wb.Shortage = (wb.Target_Revenue! - wb.Actual_Revenue!);
      expect(wb.Shortage, 800);

      wb.Actual_Revenue = 5500;
      wb.Shortage = (wb.Target_Revenue! - wb.Actual_Revenue!);
      expect(wb.Shortage, -500); // surplus
    });

    test('JSON roundtrip', () {
      final wb = _sampleWaybill(key: 'J01');
      final json = wb.toJson();
      final restored = Waybill.fromJson(json);
      expect(restored.Vehicle_No, wb.Vehicle_No);
      expect(restored.Target_Revenue, wb.Target_Revenue);
    });
  });

  group('WaybillTrip model — CRUD', () {
    test('create trip with all fields', () {
      final trip = _sampleTrip();
      expect(trip.From, 'Nairobi');
      expect(trip.To, 'Mombasa');
      expect(trip.Pax_No, 32);
      expect(trip.Fare_Amount, 500);
      expect(trip.Total, 16000);
      expect(trip.Expenses, 2000);
      expect(trip.Comments, 'Test trip');
    });

    test('edit trip fields', () {
      final trip = _sampleTrip();
      trip.Pax_No = 35;
      trip.Total = 17500;
      trip.Comments = 'Updated';
      expect(trip.Pax_No, 35);
      expect(trip.Total, 17500);
      expect(trip.Comments, 'Updated');
    });

    test('toMap produces correct format', () {
      final trip = _sampleTrip();
      final map = trip.toMap();
      expect(map['From'], 'Nairobi');
      expect(map['To'], 'Mombasa');
      expect(map['Pax_No'], 32);
      expect(map['Fare_Amount'], 500);
      expect(map['Total'], 16000);
      expect(map['Expenses'], 2000);
    });

    test('fromMap roundtrip', () {
      final original = _sampleTrip(key: 'T123');
      final map = original.toMap();
      final restored = WaybillTrip.fromMap(map);
      expect(restored.From, original.From);
      expect(restored.To, original.To);
      expect(restored.Pax_No, original.Pax_No);
      expect(restored.Fare_Amount, original.Fare_Amount);
      expect(restored.Total, original.Total);
      expect(restored.Expenses, original.Expenses);
      expect(restored.Comments, original.Comments);
    });

    test('total = pax × fare calculation', () {
      final trip = _sampleTrip();
      trip.Pax_No = 25;
      trip.Fare_Amount = 400;
      trip.Total = (trip.Pax_No! * trip.Fare_Amount!).toDouble();
      expect(trip.Total, 10000);
    });

    test('JSON roundtrip', () {
      final trip = _sampleTrip(key: 'T01');
      final json = trip.toJson();
      final restored = WaybillTrip.fromJson(json);
      expect(restored.From, trip.From);
      expect(restored.Pax_No, trip.Pax_No);
    });
  });

  // ═══════════════════════════════════════════════════════
  // JSON DESERIALIZATION TESTS
  // ═══════════════════════════════════════════════════════

  group('Waybill — JSON deserialization', () {
    test('parses Waybill entry from JSON', () {
      const json = '''{
        "Key": "WB001;abc123;",
        "Vehicle_No": "KAA 001A",
        "Fleet_No": "F01",
        "Driver": "John Doe",
        "Conductor": "Jane Smith",
        "Target_Revenue": 5000.00,
        "Actual_Revenue": 4800.00,
        "Shortage": 200.00,
        "Cash": 4800.00
      }''';
      final map = jsonDecode(json) as Map<String, dynamic>;
      expect(map['Key'], 'WB001;abc123;');
      expect(map['Vehicle_No'], 'KAA 001A');
      expect(map['Fleet_No'], 'F01');
      expect(map['Target_Revenue'], 5000);
      expect(map['Actual_Revenue'], 4800);
      expect(map['Shortage'], 200);
      expect(map['Cash'], 4800);
    });

    test('handles null optional fields', () {
      const json = '''{
        "Key": "MIN001;", "Vehicle_No": "TEST",
        "Fleet_No": null, "Driver": null, "Conductor": null
      }''';
      final map = jsonDecode(json) as Map<String, dynamic>;
      expect(map['Fleet_No'], isNull);
      expect(map['Driver'], isNull);
      expect(map['Conductor'], isNull);
    });

    test('parses Waybill with int values as double', () {
      const json = '''{
        "Key": "INT001;", "Vehicle_No": "KAR 492Y",
        "Target_Revenue": 5000, "Actual_Revenue": 4800,
        "Shortage": 200, "Cash": 4800
      }''';
      final map = jsonDecode(json) as Map<String, dynamic>;
      expect((map['Target_Revenue'] as num).toDouble(), 5000);
      expect((map['Actual_Revenue'] as num).toDouble(), 4800);
      expect((map['Shortage'] as num).toDouble(), 200);
      expect((map['Cash'] as num).toDouble(), 4800);
    });

    test('Results wrapper parses success response', () {
      const json = '''{
        "Code": 0, "Desc": "Success",
        "Contents": [{"Key":"WB001;", "Vehicle_No":"KAA 001A",
          "Target_Revenue":5000, "Actual_Revenue":4800,
          "Shortage":200, "Cash":4800}]
      }''';
      final map = jsonDecode(json) as Map<String, dynamic>;
      expect(map['Code'], 0);
      expect(map['Contents'], isA<List>());
      expect((map['Contents'] as List).length, 1);
    });

    test('Results wrapper parses error response', () {
      const json = '{"Code": -1, "Desc": "Service unavailable"}';
      final map = jsonDecode(json) as Map<String, dynamic>;
      expect(map['Code'], -1);
      expect(map['Desc'], 'Service unavailable');
      expect(map['Contents'], isNull);
    });

    test('Results parses single-object Contents (add endpoints)', () {
      const json =
          '{"Code":0,"Desc":"Successful","Contents":{"Key":"T1;","Trip_No":1,'
          '"Weign_Bridge_id":100,"From":"Nairobi","To":"Mombasa","Pax_No":1,'
          '"Fare_Amount":100,"Total":100}}';
      final r = Results<WaybillTrip>.fromJson(json, WaybillTrip.fromMap);
      expect(r.Code, 0);
      expect(r.Contents, isNotNull);
      expect(r.Contents!.length, 1);
      expect(r.Contents!.first.Trip_No, 1);
      expect(r.Contents!.first.From, 'Nairobi');
      expect(r.Contents!.first.Total, 100);
    });

    test('Results parses list Contents unchanged', () {
      const json = '{"Code":0,"Contents":[{"Trip_No":1},{"Trip_No":2}]}';
      final r = Results<WaybillTrip>.fromJson(json, WaybillTrip.fromMap);
      expect(r.Code, 0);
      expect(r.Contents!.length, 2);
    });
  });

  group('WaybillTrip — JSON deserialization', () {
    test('parses WaybillTrip from JSON', () {
      const json = '''{
        "Key":"TRIP001;", "Weign_Bridge_id":1, "Trip_No":1,
        "From":"Nairobi", "To":"Mombasa", "Pax_No":32,
        "Fare_Amount":500, "Total":16000,
        "Started_By":"Agent A", "Amount_Received":"CASH",
        "Expenses":2000, "Comments":"Test trip"
      }''';
      final map = jsonDecode(json) as Map<String, dynamic>;
      expect(map['From'], 'Nairobi');
      expect(map['To'], 'Mombasa');
      expect(map['Pax_No'], 32);
      expect(map['Fare_Amount'], 500);
      expect(map['Total'], 16000);
      expect(map['Comments'], 'Test trip');
    });

    test('calculates fare correctly', () {
      const json = '{"Pax_No":25, "Fare_Amount":400, "Total":10000}';
      final map = jsonDecode(json) as Map<String, dynamic>;
      final pax = (map['Pax_No'] as num).toInt();
      final fare = (map['Fare_Amount'] as num).toDouble();
      final total = (map['Total'] as num).toDouble();
      expect(pax * fare, total);
    });
  });

  // ═══════════════════════════════════════════════════════
  // CONTROLLER TESTS
  // ═══════════════════════════════════════════════════════

  group('WaybillController', () {
    setUp(() {
      _setupGetX();
      Get.put(WaybillController(), permanent: true);
    });
    tearDown(_teardownGetX);

    test('initial state is correct', () {
      final ctrl = Get.find<WaybillController>();
      expect(ctrl.waybills, isEmpty);
      expect(ctrl.trips, isEmpty);
      expect(ctrl.isLoading.value, false);
      expect(ctrl.selectedWaybill.value, isNull);
    });

    test('calculateShortage computes target - actual', () {
      final ctrl = Get.find<WaybillController>();
      expect(ctrl.calculateShortage(5000, 4800), 200);
      expect(ctrl.calculateShortage(5000, 5200), -200);
      expect(ctrl.calculateShortage(0, 0), 0);
    });

    test('calculateTripTotal computes pax × fare', () {
      final ctrl = Get.find<WaybillController>();
      expect(ctrl.calculateTripTotal(500, 32), 16000);
      expect(ctrl.calculateTripTotal(0, 10), 0);
    });

    test('selectedDate defaults to today', () {
      final ctrl = Get.find<WaybillController>();
      final today = DateTime.now();
      expect(ctrl.selectedDate.value.year, today.year);
      expect(ctrl.selectedDate.value.month, today.month);
      expect(ctrl.selectedDate.value.day, today.day);
    });
  });

  // ═══════════════════════════════════════════════════════
  // WIDGET TESTS
  // ═══════════════════════════════════════════════════════

  group('WaybillListPage — widget', () {
    setUp(() {
      _setupGetX();
      Get.put(WaybillController(), permanent: true);
    });
    tearDown(_teardownGetX);

    testWidgets('renders AppBar with title', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(home: WaybillListPage()),
      );
      await tester.pump();
      expect(find.text('CityHoppa Waybill'), findsOneWidget);
    });

    testWidgets('renders date bar', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(home: WaybillListPage()),
      );
      await tester.pump();
      // Should show a day-of-week date
      expect(find.byIcon(Icons.event), findsOneWidget);
    });

    testWidgets('renders search bar', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(home: WaybillListPage()),
      );
      await tester.pump();
      expect(find.byIcon(Icons.search), findsWidgets);
    });

    testWidgets('shows empty state when no entries', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(home: WaybillListPage()),
      );
      await tester.pump();
      expect(find.text('No entries yet'), findsOneWidget);
    });

    testWidgets('renders New Entry FAB', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(home: WaybillListPage()),
      );
      await tester.pump();
      expect(find.text('New Entry'), findsOneWidget);
    });

    testWidgets('renders bottom navigation bar', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(home: WaybillListPage()),
      );
      await tester.pump();
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });
  });

  group('WaybillFormPage — widget', () {
    setUp(() {
      _setupGetX();
      Get.put(WaybillController(), permanent: true);
    });
    tearDown(_teardownGetX);

    testWidgets('renders in create mode', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(home: WaybillFormPage()),
      );
      await tester.pump();
      expect(find.text('New Entry'), findsOneWidget);
    });

    testWidgets('renders in edit mode with pre-filled data', (tester) async {
      final wb = _sampleWaybill(key: 'EDIT1');
      await tester.pumpWidget(
        GetMaterialApp(home: WaybillFormPage(waybill: wb)),
      );
      await tester.pump();
      expect(find.text('Edit Entry'), findsOneWidget);
    });

    testWidgets('renders all section headers', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(home: WaybillFormPage()),
      );
      await tester.pump();
      expect(find.text('Vehicle'), findsOneWidget);
      expect(find.text('Crew'), findsOneWidget);
      expect(find.text('Date & Time'), findsOneWidget);
      expect(find.text('Revenue Metrics'), findsOneWidget);
      expect(find.text('Payment Collection'), findsOneWidget);
    });

    testWidgets('renders Fleet No field with search icon', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(home: WaybillFormPage()),
      );
      await tester.pump();
      expect(find.byIcon(Icons.search), findsWidgets);
    });

    testWidgets('renders Save Entry button', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(home: WaybillFormPage()),
      );
      await tester.pump();
      expect(find.text('Save Entry'), findsOneWidget);
    });

    testWidgets('renders revenue summary bar', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(home: WaybillFormPage()),
      );
      await tester.pump();
      expect(find.text('TARGET'), findsOneWidget);
      expect(find.text('ACTUAL'), findsOneWidget);
      expect(find.text('SHORTAGE'), findsOneWidget);
    });

    testWidgets('renders KSh prefix on cash field', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(home: WaybillFormPage()),
      );
      await tester.pump();
      expect(find.text('KSh'), findsOneWidget);
    });
  });

  group('TripListPage — widget', () {
    setUp(() {
      _setupGetX();
      final ctrl = WaybillController();
      ctrl.selectedWaybill.value = _sampleWaybill(key: 'WB1');
      Get.put(ctrl, permanent: true);
    });
    tearDown(_teardownGetX);

    testWidgets('renders trip page with correct title', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(home: TripListPage()),
      );
      await tester.pump();
      // AppBar shows "Trips — KAA 001A"
      expect(find.textContaining('Trips'), findsOneWidget);
    });

    testWidgets('shows empty trip state', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(home: TripListPage()),
      );
      await tester.pump();
      expect(find.text('No trips recorded'), findsOneWidget);
    });

    testWidgets('renders Start Trip FAB', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(home: TripListPage()),
      );
      await tester.pump();
      expect(find.text('Start Trip'), findsOneWidget);
    });

    testWidgets('Start Trip FAB opens the popup', (tester) async {
      final ctrl = Get.find<WaybillController>();
      ctrl.selectedWaybill.value = _sampleWaybill(key: 'WB1')..Entry_No = 100;
      await tester.pumpWidget(
        const GetMaterialApp(home: TripListPage()),
      );
      await tester.pump();
      await tester.tap(find.text('Start Trip'));
      await tester.pumpAndSettle();
      expect(find.text('Departure'), findsOneWidget);
      expect(find.text('Passengers'), findsOneWidget);
      expect(find.text('Fare Amount'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('Comments'), findsOneWidget);
    });

    testWidgets('Start Trip FAB opens popup even without Entry_No',
        (tester) async {
      // setUp waybill has Entry_No null — the popup must still open instantly
      await tester.pumpWidget(
        const GetMaterialApp(home: TripListPage()),
      );
      await tester.pump();
      await tester.tap(find.text('Start Trip'));
      await tester.pumpAndSettle();
      expect(find.text('Departure'), findsOneWidget);
      expect(find.text('Passengers'), findsOneWidget);
    });
  });

  group('TripFormPage — widget', () {
    setUp(() {
      _setupGetX();
      final ctrl = WaybillController();
      ctrl.selectedWaybill.value = _sampleWaybill(key: 'WB1');
      Get.put(ctrl, permanent: true);
    });
    tearDown(_teardownGetX);

    testWidgets('renders in create mode', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(home: TripFormPage()),
      );
      await tester.pump();
      expect(find.text('New Trip'), findsOneWidget);
    });

    testWidgets('renders in edit mode', (tester) async {
      final trip = _sampleTrip(key: 'T1');
      await tester.pumpWidget(
        GetMaterialApp(home: TripFormPage(trip: trip)),
      );
      await tester.pump();
      expect(find.text('Edit Trip'), findsOneWidget);
    });

    testWidgets('renders route fields', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(home: TripFormPage()),
      );
      await tester.pump();
      expect(find.text('Route'), findsOneWidget);
      expect(find.text('Passenger & Fare'), findsOneWidget);
    });

    testWidgets('renders Save Trip button', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(home: TripFormPage()),
      );
      await tester.pump();
      expect(find.text('Save Trip'), findsOneWidget);
    });
  });
}
