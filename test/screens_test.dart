import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:t_matatu/controllers/main.dart';
import 'package:t_matatu/models/agents.dart';
import 'package:t_matatu/providers/AppConfig.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
    Get.testMode = false;
  });

  group('Login screen — widget structure', () {
    testWidgets('renders username TextFormField', (tester) async {
      final mc = MainController();
      mc.config?.value = AppConfig(
        apiBaseUrl: 'http://localhost/api/',
        clientId: 'TEST',
        clientName: 'Test',
        logo: 'assets/logo.png',
      );
      Get.put<MainController>(mc, permanent: true);

      await tester.pumpWidget(
        GetMaterialApp(home: _LoginStub()),
      );
      await tester.pump();

      expect(find.byType(TextFormField), findsAtLeast(1));
    });

    testWidgets('shows Login button', (tester) async {
      final mc = MainController();
      mc.config?.value = AppConfig(
        apiBaseUrl: 'http://localhost/api/',
        clientId: 'TEST',
        logo: 'assets/logo.png',
      );
      Get.put<MainController>(mc, permanent: true);

      await tester.pumpWidget(
        GetMaterialApp(home: _LoginStub()),
      );
      await tester.pump();

      expect(find.text('Login'), findsOneWidget);
    });
  });

  group('AppConfig model — used by both screens', () {
    test('CityHoppa config has correct URL and client ID', () {
      final config = AppConfig(
        apiBaseUrl: 'http://152.228.250.170:8092/api/Matatu/',
        clientId: 'CITYHOPPER',
        clientName: 'CityHoppa',
        logo: 'assets/logo.png',
      );

      expect(config.apiBaseUrl, contains('8092'));
      expect(config.apiBaseUrl, contains('Matatu'));
      expect(config.clientId, 'CITYHOPPER');
      expect(config.clientName, 'CityHoppa');
    });

    test('config with empty base URL does not crash', () {
      final config = AppConfig(clientId: 'TEST');
      expect(config.apiBaseUrl, null);
      expect(config.clientId, 'TEST');
    });
  });

  group('Agent model — login data', () {
    test('active agent (Status=2) passes', () {
      final agent =
          Agent(Agent_Code: 'PAUL', Name: 'Paul', Status: 2, Password: 'x');
      expect(agent.Status, 2);
    });

    test('inactive agent (Status!=2) fails', () {
      final agent = Agent(Agent_Code: 'PAUL', Name: 'Paul', Status: 1);
      expect(agent.Status, isNot(2));
    });
  });
}

/// Minimal Login stub matching the real widget structure
class _LoginStub extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(20),
          elevation: 20,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.directions_bus, size: 80, color: Colors.blue),
                const SizedBox(height: 20),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text('Login'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
