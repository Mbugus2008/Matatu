import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:t_matatu/controllers/Members.dart';
import 'package:t_matatu/controllers/main.dart';
import 'package:t_matatu/controllers/waybill_controller.dart';
import 'package:t_matatu/models/agents.dart';
import 'package:t_matatu/models/member.dart';
import 'package:t_matatu/models/mpesa_transaction.dart';
import 'package:t_matatu/models/route.dart';
import 'package:t_matatu/models/waybill/waybill.dart';
import 'package:t_matatu/pages/optimized_receipt.dart';
import 'package:t_matatu/pages/waybill/start_trip_sheet.dart';
import 'package:t_matatu/providers/AppConfig.dart';
import 'package:t_matatu/providers/logger.dart';
import 'package:t_matatu/utils/crew_lookup.dart';

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

/// MemberController without the DB load — tests seed [allMembers] directly.
class _FakeMemberController extends MemberController {
  _FakeMemberController(List<Member> members) {
    allMembers.value = members;
    Crews.value = members;
  }

  @override
  Future<void> initialize() async {
    // Deliberately no DB access in tests.
  }
}

Member _member(String no, String name, Crew_type type, {String? vehicle}) =>
    Member(No: no, Name: name, Crew_Type: type, Vehicle: vehicle);

Waybill _sampleWaybill() => Waybill(
      Vehicle_No: 'KAA 001A',
      Fleet_No: 'F01',
      Date: DateTime(2026, 7, 28),
    );

void main() {
  // ═══════════════════════════════════════════════════════
  // AGENT — TRIP EXPENSE PERMISSIONS
  // ═══════════════════════════════════════════════════════

  group('Agent — trip expense permissions', () {
    test('Admin (1) can add trip expenses', () {
      expect(Agent(Account_type: 1).canAddTripExpenses, isTrue);
    });

    test('Supervisor (2) can add trip expenses', () {
      expect(Agent(Account_type: 2).canAddTripExpenses, isTrue);
    });

    test('other account types cannot add trip expenses', () {
      for (final type in [0, 3, 4, 5, 6]) {
        expect(
          Agent(Account_type: type).canAddTripExpenses,
          isFalse,
          reason: 'Account_type $type must not add trip expenses',
        );
      }
    });

    test('missing account type cannot add trip expenses', () {
      expect(Agent().canAddTripExpenses, isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════
  // ROUTE CODES
  // ═══════════════════════════════════════════════════════

  group('RouteService — codeFromDescription', () {
    test('uppercases and drops separators', () {
      expect(RouteService.codeFromDescription('Ambassader'), 'AMBASSADER');
    });

    test('keeps digits — they are part of real route codes', () {
      expect(RouteService.codeFromDescription('32 - Kencom'), '32KENCOM');
    });

    test('trims long descriptions to 20 characters', () {
      const description = 'Updated Route - Nairobi Express';
      final code = RouteService.codeFromDescription(description);
      expect(code.length, 20);
      expect(code, 'UPDATEDROUTENAIROBIE');
    });

    test('an existing valid code passes through unchanged', () {
      expect(RouteService.codeFromDescription('KENCOM'), 'KENCOM');
      expect(RouteService.codeFromDescription('kencom'), 'KENCOM');
    });

    test('falls back to a generated code when nothing alphanumeric remains',
        () {
      final code = RouteService.codeFromDescription('---');
      expect(code, startsWith('ROUTE'));
      expect(RegExp(r'^ROUTE\d{1,5}$').hasMatch(code), isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════
  // CREW AUTO-FILL (START TRIP)
  // ═══════════════════════════════════════════════════════

  group('Crew lookup — Start Trip auto-fill', () {
    setUp(() {
      _setupGetX();
      Get.put<MemberController>(
        _FakeMemberController([
          _member('A100', 'John Doe', Crew_type.Driver, vehicle: 'KAA 001A'),
          _member('A200', 'Jane Smith', Crew_type.Conductor,
              vehicle: 'KAA 001A'),
          // Second conductor on the same vehicle — the first one wins.
          _member('A400', 'Mary Wanjiku', Crew_type.Conductor,
              vehicle: 'KAA 001A'),
          _member('B100', 'Peter Otieno', Crew_type.Driver, vehicle: 'KBB 002B'),
        ]),
        permanent: true,
      );
    });
    tearDown(_teardownGetX);

    test('returns the driver and first conductor attached to the vehicle', () {
      expect(crewNumbersForVehicle('KAA 001A'), ('A100', 'A200'));
    });

    test('returns nulls when nobody is attached to the vehicle', () {
      expect(crewNumbersForVehicle('KCC 003C'), (null, null));
    });

    test('null or empty vehicle returns nulls', () {
      expect(crewNumbersForVehicle(null), (null, null));
      expect(crewNumbersForVehicle('  '), (null, null));
    });

    test('vehicle matching ignores case and surrounding spaces', () {
      expect(crewNumbersForVehicle('  kaa 001a '), ('A100', 'A200'));
    });

    test('resolves a crew name to its number', () {
      expect(crewNumberFor('Jane Smith'), 'A200');
    });

    test('a stored crew number passes straight through', () {
      expect(crewNumberFor('A100'), 'A100');
    });

    test('prefers the member attached to the given vehicle', () {
      // Same name on two vehicles — the vehicle decides.
      Get.find<MemberController>().allMembers.add(
            _member('B200', 'John Doe', Crew_type.Driver,
                vehicle: 'KBB 002B'),
          );
      expect(crewNumberFor('John Doe', vehicle: 'KBB 002B'), 'B200');
    });

    test('unknown name resolves to null', () {
      expect(crewNumberFor('Nobody Here'), isNull);
      expect(crewNumberFor(null), isNull);
    });

    test('crewLabelFor shows the name for a known number', () {
      expect(crewLabelFor('A100'), 'John Doe');
    });

    test('crewLabelFor falls back to the raw value and a dash', () {
      expect(crewLabelFor('UNKNOWN-X'), 'UNKNOWN-X');
      expect(crewLabelFor(null), '-');
      expect(crewLabelFor('  '), '-');
    });
  });

  // ═══════════════════════════════════════════════════════
  // CITYHOPPA RECEIPT — EXPECTED CASH
  // ═══════════════════════════════════════════════════════

  group('Receipt — expected cash', () {
    test('target minus M-Pesa already paid', () {
      expect(Receipt.expectedCashAmount(6770, 2000, 0), 4770);
    });

    test('target minus M-Pesa and trip expenses', () {
      expect(Receipt.expectedCashAmount(6770, 2000, 770), 4000);
    });

    test('nothing left when M-Pesa and expenses cover the target', () {
      expect(Receipt.expectedCashAmount(6770, 6000, 770), 0);
    });

    test('never negative when M-Pesa exceeds the target', () {
      expect(Receipt.expectedCashAmount(5000, 7200, 0), 0);
    });

    test('expenses alone can zero it out', () {
      expect(Receipt.expectedCashAmount(5000, 1000, 5000), 0);
    });
  });

  // ═══════════════════════════════════════════════════════
  // OPEN TRIPS SUMMARY (RECEIPT TARGET)
  // ═══════════════════════════════════════════════════════

  group('WaybillService — open trips summary', () {
    WaybillTrip trip({int? no, double? total, double? expenses, DateTime? to}) =>
        WaybillTrip(Trip_No: no, Total: total, Expenses: expenses, To_Time: to);

    test('sums the totals and expenses of open trips only', () {
      final (count, total, expenses) = WaybillService.openTripsSummary([
        trip(
            no: 1,
            total: 2550,
            expenses: 200,
            to: DateTime(2026, 9, 29, 10, 0)),
        trip(no: 2, total: 3060, expenses: 150),
        trip(no: 3, total: 1000, expenses: 50),
      ]);
      expect(count, 2);
      expect(total, 4060);
      expect(expenses, 200);
    });

    test('no open trips gives zeros', () {
      final (count, total, expenses) = WaybillService.openTripsSummary([
        trip(
            no: 1,
            total: 2550,
            expenses: 200,
            to: DateTime(2026, 9, 29, 10, 0)),
      ]);
      expect(count, 0);
      expect(total, 0);
      expect(expenses, 0);
    });

    test('null totals and expenses count as zero', () {
      final (count, total, expenses) = WaybillService.openTripsSummary([
        trip(no: 1),
        trip(no: 2, total: 500, expenses: 80),
      ]);
      expect(count, 2);
      expect(total, 500);
      expect(expenses, 80);
    });
  });

  // ═══════════════════════════════════════════════════════
  // M-PESA TRANSACTIONS (RECEIPT)
  // ═══════════════════════════════════════════════════════

  group('MpesaTransaction — parsing & totals', () {
    test('sums Paid_In and ignores nulls', () {
      final list = [
        MpesaTransaction(Paid_In: 1200),
        MpesaTransaction(Paid_In: null),
        MpesaTransaction(Paid_In: 500),
      ];
      expect(MpesaTransactionService.totalOf(list), 1700);
    });

    test('empty list is zero', () {
      expect(MpesaTransactionService.totalOf(const []), 0);
    });

    test('parses NAV en-US dates and ISO dates', () {
      final us = MpesaTransaction.fromMap(
          {'Paid_In': 100, 'Transaction_Date': '09/30/2026 10:30:00'});
      expect(us.Transaction_Date?.month, 9);
      expect(us.Transaction_Date?.day, 30);

      final iso = MpesaTransaction.fromMap(
          {'Paid_In': 100, 'Transaction_Date': '2026-09-30T10:30:00'});
      expect(iso.Transaction_Date?.year, 2026);
      expect(iso.Transaction_Date?.day, 30);
    });

    test('receipted rows are flagged and skip marking', () {
      final byPosted = MpesaTransaction.fromMap(
          {'Paid_In': 100, 'Posted_ReceiptNo': '1759197123456789'});
      expect(byPosted.isReceipted, isTrue);

      final byStamp = MpesaTransaction.fromMap(
          {'Paid_In': 100, 'Receipted_At': '09/30/2026 10:30:00'});
      expect(byStamp.isReceipted, isTrue);

      // NAV writes 01/01/0001 for "never stamped".
      final untouched = MpesaTransaction.fromMap(
          {'Paid_In': 100, 'Receipted_At': '01/01/0001 00:00:00'});
      expect(untouched.isReceipted, isFalse);

      final open = MpesaTransaction(Key: 'abc', Paid_In: 100);
      expect(open.isReceipted, isFalse);
    });

    test('mark payload carries Key, Posted_ReceiptNo, Receipted_At, agent',
        () {
      final txn =
          MpesaTransaction(Key: 'rec-1', Loan_No: 'KCQ779P', Paid_In: 250);
      final map = txn.toMarkMap(receiptNo: '1759197123456789', agent: 'pau');
      expect(map['Key'], 'rec-1');
      expect(map['Posted_ReceiptNo'], '1759197123456789');
      expect(map['Receipted_At'], isNotNull);
      expect(map['Receipted_By'], 'pau');
      // The M-Pesa transaction code must never be overwritten.
      expect(map.containsKey('Receipt_No'), isFalse);
      // Read-only row data is not re-sent, so BC leaves it untouched.
      expect(map.containsKey('Paid_In'), isFalse);
      expect(map.containsKey('Loan_No'), isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════
  // OPEN TRIP RULE (EXPENSES)
  // ═══════════════════════════════════════════════════════

  group('WaybillTrip — open trip rule', () {
    test('a trip without an end time is open', () {
      final trip = WaybillTrip(
        Trip_No: 1,
        From: 'KENCOM',
        From_Time: DateTime(2026, 7, 28, 8, 0),
      );
      expect(trip.isOpen, isTrue);
    });

    test('setting the end time closes the trip', () {
      final trip = WaybillTrip(
        Trip_No: 1,
        From_Time: DateTime(2026, 7, 28, 8, 0),
        To_Time: DateTime(2026, 7, 28, 10, 0),
      );
      expect(trip.isOpen, isFalse);
    });

    test('route description survives the API and DB maps', () {
      final trip = WaybillTrip(
        Trip_No: 1,
        From: '46 - KEN',
        Description: 'Kencom - Kawangware',
      );
      expect(WaybillTrip.fromMap(trip.toMap()).Description,
          'Kencom - Kawangware');
      expect(WaybillTrip.fromMap_db(trip.toMap_fortable()).Description,
          'Kencom - Kawangware');
    });

    test('dirty flag survives the DB map', () {
      final trip = WaybillTrip(Trip_No: 1, From: '46 - KEN');
      trip.dirty = true;
      trip.sent = false;
      final row = trip.toMap_fortable();
      expect(row['Dirty'], 1);
      final restored = WaybillTrip.fromMap_db(row);
      expect(restored.dirty, isTrue);
      trip.dirty = false;
      expect(trip.toMap_fortable()['Dirty'], 0);
    });
  });

  // ═══════════════════════════════════════════════════════
  // START TRIP SHEET — WIDGET
  // ═══════════════════════════════════════════════════════

  group('StartTripSheet — widget', () {
    setUp(() {
      _setupGetX();
      Get.put(WaybillController(), permanent: true);
    });
    tearDown(_teardownGetX);

    Future<void> pumpSheet(WidgetTester tester, {Waybill? waybill}) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: StartTripSheet(
              controller: Get.find<WaybillController>(),
              waybill: waybill,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('fresh start: vehicle picker comes first, then trip fields',
        (tester) async {
      await pumpSheet(tester);

      // The silent-entry promise is explained up front.
      expect(
        find.textContaining("the day's waybill is created"),
        findsOneWidget,
      );
      expect(find.text('Start Trip'), findsOneWidget); // sheet title
      expect(find.text('Vehicle'), findsOneWidget); // picker label
      expect(find.text('From'), findsOneWidget);
      // The To route is gone - trips only carry the agent's From route.
      expect(find.text('To'), findsNothing);
      expect(find.text('Departure'), findsOneWidget);
      expect(find.text('Passengers'), findsOneWidget);
      expect(find.text('Fare Amount'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('Comments'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('trip entry: no vehicle picker, entry context is shown',
        (tester) async {
      await pumpSheet(tester, waybill: _sampleWaybill());

      expect(find.textContaining('the trip is added to this entry'),
          findsOneWidget);
      // The picker is gone — the entry already owns the vehicle.
      expect(find.text('Vehicle'), findsNothing);
      // Trip fields are still there; To is gone as well.
      expect(find.text('From'), findsOneWidget);
      expect(find.text('To'), findsNothing);
      expect(find.text('Start'), findsOneWidget);
    });

    testWidgets('start without a vehicle asks for one', (tester) async {
      await pumpSheet(tester);

      // The sheet scrolls — bring the action button into the viewport first.
      await tester.ensureVisible(find.text('Start'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();

      expect(find.text('Select the vehicle from the list'), findsOneWidget);
    });

    testWidgets('route field without cached routes explains the problem',
        (tester) async {
      await pumpSheet(tester);

      await tester.tap(find.text('Select route').first);
      await tester.pumpAndSettle();

      expect(find.text('No routes available. Check the connection, then '
          'try again.'), findsOneWidget);
    });
  });
}
