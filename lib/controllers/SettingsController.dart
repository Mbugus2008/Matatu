import 'package:get/get.dart';
import 'package:t_matatu/models/Utils/Settings.dart';
import 'package:t_matatu/network/Apis.dart';
import 'package:t_matatu/network/results/results.dart';

class SettingsController extends GetxController {
  final Rx<Settings?> settings = Rx<Settings?>(Settings(WorkingDate: DateTime.now()));

  Future<void> fetchWorkingDate() async {
    try {
      final response = await ApiClient().postdata("TransactionDate", "");
      if (response.statusCode == 200) {
        final results =
            Results2<Settings>.fromJson(response.body, Settings.fromMap);
        if (results.Code == 0 && results.Contents != null) {
      Get.find<SettingsController>().settings.value = results.Contents;
        }
      }
    } catch (e) {
      print('Error fetching settings: $e');
      Get.find<SettingsController>().settings.value = Settings(WorkingDate: DateTime.now());
    }
  }
  DateTime get workingDate => Get.find<SettingsController>().settings.value?.WorkingDate ?? DateTime.now();
}
