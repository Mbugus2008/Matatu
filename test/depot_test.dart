import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:t_matatu/models/vehicles/DeportandFuel.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put(DepotController(), permanent: true);
  });

  tearDown(() {
    Get.reset();
    Get.testMode = false;
  });

  group('DepotFuel model — dispatch data', () {
    test('parses depot record from JSON via fromMap', () {
      final json = jsonDecode('''
      {
        "Key": "K1",
        "Fleet": "123",
        "Vehicle": "KCA022Q",
        "Capacity": 8,
        "Driver_Name": "SAMY NGANGA",
        "Conductor_Name": "JEREMIAH KINGORI NJORIA",
        "On_route": true,
        "Offload": 1500,
        "Fuel": 500,
        "Amount_Paid": 2000,
        "Balance": 0,
        "Millage": 12000,
        "Defect": "None",
        "Description": ""
      }
      ''') as Map<String, dynamic>;

      final depot = DepotFuel.fromMap(json);

      expect(depot.Fleet, '123');
      expect(depot.Vehicle, 'KCA022Q');
      expect(depot.Driver_Name, 'SAMY NGANGA');
      expect(depot.On_route, true);
    });

    test('parses depot record from JSON string via fromJson', () {
      const json = '''
      {
        "Fleet": "364",
        "Vehicle": "KCA022Q",
        "Capacity": 8,
        "Driver_Name": "SAMY NGANGA",
        "Conductor_Name": "JEREMIAH KINGORI NJORIA",
        "On_route": true,
        "Offload": 1500,
        "Fuel": 500,
        "Amount_Paid": 2000,
        "Balance": 0,
        "Millage": 12000
      }
      ''';

      final depot = DepotFuel.fromJson(json);

      expect(depot.Fleet, '364');
      expect(depot.Vehicle, 'KCA022Q');
      expect(depot.On_route, true);
    });

    test('fromJson handles int Offload as double', () {
      const json = '''
      {
        "Fleet": "1",
        "Vehicle": "TEST",
        "Offload": 1500,
        "Fuel": 500,
        "Amount_Paid": 2000,
        "Balance": 0,
        "Net_Offload": 1000,
        "Total_Litres": 50,
        "Km_Litre": 10,
        "Offload_Target": 2000,
        "Offload_Balance": 500,
        "Management_Balance": 300,
        "Management": 200,
        "Management_Target": 1000,
        "On_route": true
      }
      ''';

      final depot = DepotFuel.fromJson(json);

      // All numeric fields should be double after our (as num).toDouble() fix
      expect(depot.Offload, 1500.0);
      expect(depot.Fuel, 500.0);
      expect(depot.Amount_Paid, 2000.0);
      expect(depot.Balance, 0.0);
      expect(depot.Net_Offload, 1000.0);
      expect(depot.Total_litres, 50.0);
      expect(depot.Offload_Target, 2000.0);
      expect(depot.Offload_Balance, 500.0);
      expect(depot.Management_Balance, 300.0);
      expect(depot.Management, 200.0);
      expect(depot.Management_Target, 1000.0);
    });
  });

  group('DepotController — state management', () {
    test('initial state is empty', () {
      final controller = Get.find<DepotController>();

      expect(controller.depottrans, isEmpty);
      expect(controller.checkall.value, false);
      expect(controller.updating.value, false);
    });

    test('updateDepotTrans populates data', () {
      final controller = Get.find<DepotController>();
      final record = DepotFuel.fromJson('''
      {
        "Fleet": "123",
        "Vehicle": "KCA022Q",
        "Capacity": 8,
        "Driver_Name": "SAMY",
        "Conductor_Name": "JEREMIAH",
        "On_route": true,
        "Offload": 1500,
        "Fuel": 500,
        "Amount_Paid": 2000,
        "Balance": 0,
        "Millage": 12000
      }
      ''');

      controller.updateDepotTrans([record]);

      expect(controller.depottrans.length, 1);
      expect(controller.depottrans.first.Fleet, '123');
      expect(controller.depottrans.first.Vehicle, 'KCA022Q');
    });

    test('updateDepotTrans with empty list clears data', () {
      final controller = Get.find<DepotController>();

      // First add data
      final record = DepotFuel()..Fleet = '1';
      controller.updateDepotTrans([record]);
      expect(controller.depottrans.length, 1);

      // Then clear
      controller.updateDepotTrans([]);
      expect(controller.depottrans, isEmpty);
    });

    test('checkallvehicles toggles all On_route', () {
      final controller = Get.find<DepotController>();

      controller.depottrans.addAll([
        DepotFuel()..On_route = false,
        DepotFuel()..On_route = false,
      ]);

      controller.checkallvehicles(true);

      for (final d in controller.depottrans) {
        expect(d.On_route, true);
      }
    });

    test('checkallvehicles false clears all On_route', () {
      final controller = Get.find<DepotController>();

      controller.depottrans.addAll([
        DepotFuel()..On_route = true,
        DepotFuel()..On_route = true,
      ]);

      controller.checkallvehicles(false);

      for (final d in controller.depottrans) {
        expect(d.On_route, false);
      }
    });

    test('filterDepotTrans filters by vehicle number', () {
      final controller = Get.find<DepotController>();

      final r1 = DepotFuel()..Vehicle = 'KCA022Q';
      final r2 = DepotFuel()..Vehicle = 'KCB608E';
      controller.depottrans.value = [r1, r2];
      controller.depottrans1.value = [r1, r2];

      controller.filterDepotTrans('KCA');

      expect(controller.depottrans.length, 1);
      expect(controller.depottrans.first.Vehicle, 'KCA022Q');
    });

    test('updateCheckAll reflects all-on state', () {
      final controller = Get.find<DepotController>();

      controller.depottrans.addAll([
        DepotFuel()..On_route = true,
        DepotFuel()..On_route = true,
      ]);

      controller.updateCheckAll();

      expect(controller.checkall.value, true);
    });

    test('updateCheckAll reflects mixed state', () {
      final controller = Get.find<DepotController>();

      controller.depottrans.addAll([
        DepotFuel()..On_route = true,
        DepotFuel()..On_route = false,
      ]);

      controller.updateCheckAll();

      expect(controller.checkall.value, false);
    });
  });
}
