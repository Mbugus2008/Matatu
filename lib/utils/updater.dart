import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:t_matatu/controllers/main.dart';

class UpdateController extends GetxController {
  var latestVersion = "".obs;
  var apkUrl = "".obs;
  var changelog = "".obs;
  var isDownloading = false.obs;
  var progress = 0.0.obs;

  Future<void> checkForUpdate({bool showUpToDate = true}) async {
    try {
      final updateUrl = Get.find<MainController>().config?.value.updateUrl;
      if (updateUrl == null || updateUrl.isEmpty) {
        if (showUpToDate) {
          Get.snackbar("Update", "Update URL not configured",
              snackPosition: SnackPosition.BOTTOM);
        }
        return;
      }
      final response = await http.get(Uri.parse("${updateUrl}update.json"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Support both field names for compatibility
        latestVersion.value = data["version"] ?? data["latest_version"] ?? "";
        apkUrl.value = data["apk_url"] ?? "";
        changelog.value = data["release_notes"] ?? data["changelog"] ?? "";

        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        String currentVersion = packageInfo.version;

        if (latestVersion.value.isNotEmpty &&
            latestVersion.value != currentVersion) {
          _showUpdateDialog();
        } else if (showUpToDate) {
          Get.snackbar(
            "Up to Date",
            "You are running the latest version ($currentVersion)",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        }
      } else {
        if (showUpToDate) {
          Get.snackbar("Update", "Could not check for updates",
              snackPosition: SnackPosition.BOTTOM);
        }
      }
    } catch (e) {
      debugPrint("Update check failed: $e");
      if (showUpToDate) {
        Get.snackbar("Update", "Failed to check for updates: $e",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white);
      }
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
                Text(
                    "Downloading update... ${progress.value.toStringAsFixed(0)}%"),
                const SizedBox(height: 10),
                LinearProgressIndicator(value: progress.value / 100),
              ],
            );
          }
          return Text(
              "New version ${latestVersion.value} is available.\n\n${changelog.value}");
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
