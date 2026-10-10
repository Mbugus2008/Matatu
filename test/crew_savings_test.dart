import 'package:flutter_test/flutter_test.dart';
import 'package:t_matatu/controllers/TypesController.dart';
import 'package:t_matatu/models/trantypes.dart';

void main() {
  group('TranTypes.crewNoFor', () {
    test('driver savings map to the driver number', () {
      expect(TranTypes.crewNoFor('SAVINGSCREW', 'A123', 'B456'), 'A123');
    });

    test('conductor savings map to the conductor number', () {
      expect(TranTypes.crewNoFor('SAVINGSCREW1', 'A123', 'B456'), 'B456');
    });

    test('other types have no crew number', () {
      expect(TranTypes.crewNoFor('SAVINGS', 'A123', 'B456'), isNull);
      expect(TranTypes.crewNoFor('OFFLOAD', 'A123', 'B456'), isNull);
    });
  });

  group('TranTypes.crewSavingsDescription', () {
    test('appends the crew number in brackets', () {
      expect(TranTypes.crewSavingsDescription('Crew Savings(Dr)', 'B098'),
          'Crew Savings(Dr)(B098)');
      expect(TranTypes.crewSavingsDescription('Crew (Conductor)', 'A356'),
          'Crew (Conductor)(A356)');
    });

    test('never appends twice', () {
      expect(TranTypes.crewSavingsDescription('Crew Savings(Dr)(B098)', 'B098'),
          'Crew Savings(Dr)(B098)');
    });

    test('empty crew number leaves the text alone', () {
      expect(TranTypes.crewSavingsDescription('Crew (Conductor)', null),
          'Crew (Conductor)');
      expect(TranTypes.crewSavingsDescription('Crew (Conductor)', ''),
          'Crew (Conductor)');
    });
  });

  group('TranTypes.descriptionMatchesType', () {
    test('plain descriptions match their type name', () {
      expect(TranTypes.descriptionMatchesType('Offload', 'Offload'), isTrue);
      expect(TranTypes.descriptionMatchesType('Offload Parking', 'Offload'),
          isFalse);
    });

    test('crew savings with a crew number match the plain type', () {
      expect(
          TranTypes.descriptionMatchesType(
              'Crew Savings(Dr)(A091)', 'Crew Savings(Dr)'),
          isTrue);
      expect(
          TranTypes.descriptionMatchesType(
              'Crew (Conductor)(B022)', 'Crew (Conductor)'),
          isTrue);
    });

    test('different types do not match', () {
      expect(
          TranTypes.descriptionMatchesType('Crew Savings(Dr)(A091)', 'Savings'),
          isFalse);
      expect(
          TranTypes.descriptionMatchesType(
              'Crew Savings(Dr)(A091)', 'Crew (Conductor)'),
          isFalse);
      expect(
          TranTypes.descriptionMatchesType('Offload', 'Management'), isFalse);
    });

    test('empty values never match', () {
      expect(TranTypes.descriptionMatchesType(null, 'Offload'), isFalse);
      expect(TranTypes.descriptionMatchesType('Offload', null), isFalse);
      expect(TranTypes.descriptionMatchesType('', ''), isFalse);
    });
  });

  group('TranTypes.typeForTransaction', () {
    final driverSavings =
        TranTypes(Code: 'SAVINGSCREW', Name: 'Crew Savings(Dr)');
    final conductorSavings =
        TranTypes(Code: 'SAVINGSCREW1', Name: 'Crew (Conductor)');
    final parking = TranTypes(Code: 'NCC PARKING', Name: 'Parking');
    final types = [driverSavings, conductorSavings, parking];

    test('matches by the transaction code', () {
      expect(TranTypes.typeForTransaction(types, 'SAVINGSCREW1', null),
          same(conductorSavings));
      // The description differs from the name, but the code still resolves.
      expect(TranTypes.typeForTransaction(types, 'NCC PARKING', 'Parking'),
          same(parking));
    });

    test('trims the code', () {
      expect(TranTypes.typeForTransaction(types, ' SAVINGSCREW ', null),
          same(driverSavings));
    });

    test('an unknown code does not fall back to the description', () {
      expect(
          TranTypes.typeForTransaction(
              types, 'WHATEVER', 'Crew Savings(Dr)(A091)'),
          isNull);
    });

    test('a row without a code falls back to the description', () {
      expect(
          TranTypes.typeForTransaction(types, null, 'Crew Savings(Dr)(A091)'),
          same(driverSavings));
      expect(
          TranTypes.typeForTransaction(types, '  ', 'Parking'), same(parking));
    });

    test('nothing to match gives null', () {
      expect(TranTypes.typeForTransaction(types, null, 'Nothing'), isNull);
      expect(TranTypes.typeForTransaction(types, '', null), isNull);
    });
  });

  group('TransTypeController.compareByOrder', () {
    TranTypes type(String code, int order, double amount) =>
        TranTypes(Code: code, Order: order)..VehicleAmount = amount;

    test('sorts by the Order column, ascending', () {
      final list = [
        type('C', 3, 5000),
        type('A', 1, 10),
        type('B', 2, 100),
      ]..sort(TransTypeController.compareByOrder);
      expect(list.map((t) => t.Code).toList(), ['A', 'B', 'C']);
    });

    test('same Order falls back to biggest expected first', () {
      final list = [
        type('SMALL', 5, 100),
        type('BIG', 5, 900),
      ]..sort(TransTypeController.compareByOrder);
      expect(list.map((t) => t.Code).toList(), ['BIG', 'SMALL']);
    });
  });
}
