import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:t_matatu/controllers/main.dart';

class UpdateController extends GetxController {
  var latestVersion = "".obs;
  var apkUrl = "".obs;
  var changelog = "".obs;
  var isDownloading = false.obs;
  var progress = 0.0.obs;

  Future<void> checkForUpdate() async {
    try {
      final response = await http.get(Uri.parse(  "${Get.find<MainController>().config?.value.updateUrl}update.json"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        latestVersion.value = data["latest_version"];
        apkUrl.value = data["apk_url"];
        changelog.value = data["changelog"];

        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        String currentVersion = packageInfo.version;
        if (latestVersion.value != currentVersion) {
          _showUpdateDialog();
        }
      }
    } catch (e) {
      debugPrint("Update check failed: $e");
    }
  }

  void _showUpdateDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text("Update Available"),
        content: Obx(() {
          if (isDownloading.value) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Downloading update... ${progress.value.toStringAsFixed(0)}%"),
                const SizedBox(height: 10),
                LinearProgressIndicator(value: progress.value / 100),
              ],
            );
          }
          return Text("New version ${latestVersion.value} is available.\n\n${changelog.value}");
        }),
        actions: [
          Obx(() => !isDownloading.value
              ? TextButton(
                  child: const Text("Later"),
                  onPressed: () => Get.back(),
                )
              : const SizedBox.shrink()),
          Obx(() => !isDownloading.value
              ? ElevatedButton(
                  child: const Text("Update Now"),
                  onPressed: () {
                    _downloadAndInstallApk(apkUrl.value);
                  },
                )
              : const SizedBox.shrink()),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _downloadAndInstallApk(String url) async {
    try {
      isDownloading.value = true;
      final dir = await getExternalStorageDirectory();
      final filePath = "${dir!.path}/update.apk";

      await Dio().download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            progress.value = (received / total * 100);
          }
        },
      );

      isDownloading.value = false;
      Get.back(); // close dialog
      await OpenFilex.open(filePath); // triggers Android install prompt
    } catch (e) {
      isDownloading.value = false;
      Get.snackbar("Update Failed", "Could not download update: $e");
    }
  }
}