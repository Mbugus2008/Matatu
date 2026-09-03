import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:t_matatu/controllers/main.dart';
import 'package:t_matatu/models/vehicles/DeportandFuel.dart';
import 'package:t_matatu/providers/AppConfig.dart';
import 'package:t_matatu/providers/logger.dart';

/// Logger stub that avoids path_provider (not available in tests).
class _TestLogger extends LoggerService {
  @override
  Future<void> onInit() async {}
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put<LoggerService>(_TestLogger(), permanent: true);
    Get.put(MainController(), permanent: true);
    Get.find<MainController>().config!.value = AppConfig(
      apiBaseUrl: 'http://services.trimline.co.ke:8092/api/Matatu/',
      clientId: 'CITYHOPPER',
      clientName: 'CityHoppa',
    );
    Get.put(DepotController(), permanent: true);
  });

  tearDown(() {
    Get.reset();
    Get.testMode = false;
  });

  test('batch endpoint saves dirty depots in one request', () async {
    // Load today's depot rows through the app's own API client.
    await DepotFuel().getdata(DateTime.now());
    var rows = Get.find<DepotController>().depottrans1.toList();
    if (rows.isEmpty) {
      await DepotFuel()
          .getdata(DateTime.now().subtract(const Duration(days: 1)));
      rows = Get.find<DepotController>().depottrans1.toList();
    }
    expect(rows, isNotEmpty, reason: 'No depot data for today or yesterday');

    final depot = rows.first;
    depot.dirty = true; // re-save an unchanged row (idempotent)

    await DepotFuel().updatedepot(Get.find<DepotController>().depottrans);

    final ctrl = Get.find<DepotController>();
    expect(depot.dirty, isFalse,
        reason: 'Row should be marked clean after batch save');
    expect(ctrl.updateTotal.value, greaterThan(0));
    expect(ctrl.updateProgress.value, ctrl.updateTotal.value);
  });
}
