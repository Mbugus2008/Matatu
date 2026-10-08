import 'package:flutter_test/flutter_test.dart';
import 'package:t_matatu/controllers/TypesController.dart';
import 'package:t_matatu/models/trantypes.dart';

void main() {
  group('TransTypeController.resetDistribution', () {
    test('clears allocated amounts and checks, keeps expected/today', () {
      final controller = TransTypeController();
      final offload = TranTypes(Code: 'OFFLOAD', Name: 'Offload', Order: 1);
      offload.VehicleAmount = 4000;
      offload.Amounttoday = 1000;
      offload.Amountedited = 3000;
      offload.Checked = true;
      offload.eAmount.text = '3000.00';
      final savings = TranTypes(Code: 'SAVINGS', Name: 'Savings', Order: 2);
      savings.Amountedited = 500;
      savings.Checked = true;
      savings.eAmount.text = '500.00';
      controller.vehicleTrantypes.value = [offload, savings];

      controller.resetDistribution();

      for (final type in [offload, savings]) {
        expect(type.Amountedited, 0);
        expect(type.Checked, false);
        expect(type.eAmount.text, '0.00');
      }
      // Today's collection and the expected amount are not part of the
      // working distribution — they must survive.
      expect(offload.VehicleAmount, 4000);
      expect(offload.Amounttoday, 1000);
    });

    test('tolerates an empty type list', () {
      final controller = TransTypeController();
      controller.resetDistribution();
      expect(controller.vehicleTrantypes, isEmpty);
    });
  });
}
