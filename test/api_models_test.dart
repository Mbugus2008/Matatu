import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:t_matatu/models/Tamounts.dart';
import 'package:t_matatu/models/agents.dart';
import 'package:t_matatu/models/vehicles/vehicle.dart';
import 'package:t_matatu/network/results/results.dart';

void main() {
  group('Vehicles.fromMap — JSON type safety', () {
    test('parses API response with int values as double', () {
      const json = '''
      {
        "Key": "28;YcMAAAJ7/0sAQwBNAzAFo=8;249563980;",
        "Vehicle_Number": "KAR 492Y",
        "Fleet_No": "463",
        "Vehicle_Type": 8,
        "Vehicle_TypeSpecified": true,
        "Daily_Contribution": 4550,
        "Daily_ContributionSpecified": true,
        "Offload": 1500,
        "OffloadSpecified": true,
        "Management": 6470,
        "ManagementSpecified": true,
        "Mpesa": 0,
        "MpesaSpecified": true,
        "Cash": 7970,
        "CashSpecified": true,
        "Date_Filter": "01/01/0001 00:00:00",
        "Date_FilterSpecified": true,
        "Operation": 0,
        "OperationSpecified": false,
        "Wadge_5": 0,
        "Wadge_5Specified": false
      }
      ''';

      final vehicle = Vehicles.fromMap(jsonDecode(json));

      expect(vehicle.Vehicle_Number, 'KAR 492Y');
      expect(vehicle.Fleet_No, '463');
      expect(vehicle.Daily_Contribution, 4550.0);
      expect(vehicle.Offload, 1500.0);
      expect(vehicle.Management, 6470.0);
      expect(vehicle.Mpesa, 0.0);
      expect(vehicle.Cash, 7970.0);
      expect(vehicle.Vehicle_Type?.index, 8);
      expect(vehicle.total, 7970.0); // Offload + Management
    });

    test('parses API response with zero values', () {
      const json = '''
      {
        "Key": "test;0;",
        "Vehicle_Number": "KAS519L",
        "Fleet_No": "EXX347",
        "Vehicle_Type": 2,
        "Vehicle_TypeSpecified": true,
        "Daily_Contribution": 4550,
        "Daily_ContributionSpecified": true,
        "Offload": 0,
        "OffloadSpecified": true,
        "Management": 0,
        "ManagementSpecified": true,
        "Mpesa": 0,
        "MpesaSpecified": true,
        "Cash": 0,
        "CashSpecified": true
      }
      ''';

      final vehicle = Vehicles.fromMap(jsonDecode(json));

      expect(vehicle.Offload, 0.0);
      expect(vehicle.Management, 0.0);
      expect(vehicle.Mpesa, 0.0);
      expect(vehicle.Cash, 0.0);
      expect(vehicle.total, 0.0);
    });

    test('parses null fields gracefully', () {
      const json = '{}';
      final vehicle = Vehicles.fromMap(jsonDecode(json));

      expect(vehicle.Vehicle_Number, null);
      expect(vehicle.Fleet_No, null);
      expect(vehicle.Daily_Contribution, null);
      expect(vehicle.Offload, null);
      expect(vehicle.Management, null);
      expect(vehicle.Mpesa, null);
      expect(vehicle.Cash, null);
      expect(vehicle.Vehicle_Type, null);
      expect(vehicle.total, 0.0); // defaults to 0
    });
  });

  group('Results.fromJson — wraps API response', () {
    test('parses Dailytrans response with multiple vehicles', () {
      const json = '''
      {
        "Code": 0,
        "Desc": "Successful",
        "Contents": [
          {
            "Key": "K1",
            "Vehicle_Number": "KAR 492Y",
            "Fleet_No": "463",
            "Vehicle_Type": 8,
            "Daily_Contribution": 4550,
            "Offload": 1500,
            "Management": 6470,
            "Mpesa": 0,
            "Cash": 7970
          },
          {
            "Key": "K2",
            "Vehicle_Number": "KAT134Y",
            "Fleet_No": "477",
            "Vehicle_Type": 8,
            "Daily_Contribution": 4550,
            "Offload": 0,
            "Management": 0,
            "Mpesa": 0,
            "Cash": 0
          }
        ]
      }
      ''';

      final results = Results<Vehicles>.fromJson(json, Vehicles.fromMap);

      expect(results.Code, 0);
      expect(results.Desc, 'Successful');
      expect(results.Contents, isNotNull);
      expect(results.Contents!.length, 2);
      expect(results.Contents![0].Vehicle_Number, 'KAR 492Y');
      expect(results.Contents![1].Fleet_No, '477');
    });

    test('parses agents response', () {
      const json = '''
      {
        "Code": 0,
        "Desc": "Successful",
        "Contents": [
          {
            "Key": "A1",
            "Agent_Code": "AGNES",
            "Name": "Agnes",
            "Status": 2,
            "Account_type": 1,
            "Account_Balance": 1500
          },
          {
            "Key": "A2",
            "Agent_Code": "PAUL",
            "Name": "Paul Njoroge",
            "Status": 2,
            "Account_type": 1,
            "Account_Balance": 0
          }
        ]
      }
      ''';

      final results = Results<Agent>.fromJson(json, Agent.fromMap);

      expect(results.Code, 0);
      expect(results.Contents!.length, 2);
      expect(results.Contents![0].Agent_Code, 'AGNES');
      expect(results.Contents![0].Account_Balance, 1500.0);
      expect(results.Contents![1].Account_Balance, 0.0);
    });

    test('handles API error response (Code: -1)', () {
      const json = '''
      {
        "Code": -1,
        "Desc": "The tenant 'default' is not accessible.",
        "Contents": null
      }
      ''';

      final results = Results<Vehicles>.fromJson(json, Vehicles.fromMap);

      expect(results.Code, -1);
      expect(results.Desc, contains('tenant'));
      expect(results.Contents, null);
    });
  });

  group('Tamounts.fromMap', () {
    test('parses transtypesamounts response with int amount', () {
      const json = '''
      {
        "Key": "T1",
        "Code": "SAVINGS",
        "Vehicle_Type": 8,
        "Amount": 500,
        "Name": "Savings"
      }
      ''';

      final tamount = Tamounts.fromMap(jsonDecode(json));

      expect(tamount.Code, 'SAVINGS');
      expect(tamount.Amount, 500.0);
      expect(tamount.Name, 'Savings');
    });
  });

  group('Agent.fromMap — login data', () {
    test('parses agent with int Account_Balance', () {
      const json = '''
      {
        "Key": "A1",
        "Agent_Code": "PAUL",
        "Name": "Paul Njoroge",
        "Status": 2,
        "Account_type": 1,
        "Account_Balance": 0
      }
      ''';

      final agent = Agent.fromMap(jsonDecode(json));

      expect(agent.Agent_Code, 'PAUL');
      expect(agent.Status, 2);
      expect(agent.Account_Balance, 0.0);
      expect(agent.Account_type, 1);
    });

    test('parses agent with null Account_Balance', () {
      const json = '''
      {
        "Key": "A2",
        "Agent_Code": "TEST",
        "Name": "Test Agent"
      }
      ''';

      final agent = Agent.fromMap(jsonDecode(json));

      expect(agent.Agent_Code, 'TEST');
      expect(agent.Account_Balance, null);
    });
  });
}
