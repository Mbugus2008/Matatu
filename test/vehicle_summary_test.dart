import 'package:flutter_test/flutter_test.dart';
import 'package:t_matatu/models/vehicles/vehicle.dart';

void main() {
  group('Vehicles.total — computed field', () {
    test('total = Offload + Management', () {
      final v = Vehicles(Offload: 1500, Management: 6470);
      expect(v.total, 7970.0);
    });

    test('total with null Offload defaults to 0', () {
      final v = Vehicles(Offload: null, Management: 200);
      expect(v.total, 200.0);
    });

    test('total with null Management defaults to 0', () {
      final v = Vehicles(Offload: 300, Management: null);
      expect(v.total, 300.0);
    });

    test('total with both null is 0', () {
      final v = Vehicles(Offload: null, Management: null);
      expect(v.total, 0.0);
    });
  });

  group('Vehicles — sorting by Fleet_No', () {
    test('sorts numerically by Fleet_No string', () {
      final list = <Vehicles>[
        Vehicles(Fleet_No: '10', Vehicle_Number: 'A'),
        Vehicles(Fleet_No: '2', Vehicle_Number: 'B'),
        Vehicles(Fleet_No: '1', Vehicle_Number: 'C'),
      ];

      list.sort((a, b) => a.Fleet_No!.compareTo(b.Fleet_No as String));

      // String sort: "1" < "10" < "2"
      expect(list[0].Fleet_No, '1');
      expect(list[1].Fleet_No, '10');
      expect(list[2].Fleet_No, '2');
    });
  });

  group('Vehicles — status indicator logic', () {
    test('vehicle with total > 0 is active', () {
      final v = Vehicles(Offload: 100);
      expect(v.total > 0, true);
    });

    test('vehicle with total = 0 is inactive', () {
      final v = Vehicles(Offload: 0, Management: 0);
      expect(v.total > 0, false);
    });

    test(
        'vehicle with Cash > 0 but no Offload/Management is inactive (total=0)',
        () {
      final v = Vehicles(Cash: 5000, Offload: 0, Management: 0);
      expect(v.total, 0.0);
    });
  });

  group('Vehicles — vehicle type mapping', () {
    test('Vehicle_Type 8 maps to index 8', () {
      final map = {'Vehicle_Type': 8};
      final v = Vehicles.fromMap(map);
      expect(v.Vehicle_Type?.index, 8);
    });

    test('Vehicle_Type 2 maps to index 2', () {
      final map = {'Vehicle_Type': 2};
      final v = Vehicles.fromMap(map);
      expect(v.Vehicle_Type?.index, 2);
    });

    test('null Vehicle_Type does not crash', () {
      final v = Vehicles.fromMap({});
      expect(v.Vehicle_Type, null);
    });
  });

  group('Vehicles — fromMap empty data', () {
    test('all fields null when map is empty', () {
      final v = Vehicles.fromMap({});

      expect(v.Vehicle_Number, null);
      expect(v.Fleet_No, null);
      expect(v.Vehicle_Type, null);
      expect(v.Daily_Contribution, null);
      expect(v.Offload, null);
      expect(v.Management, null);
      expect(v.Mpesa, null);
      expect(v.Cash, null);
      expect(v.total, 0.0);
    });
  });
}
