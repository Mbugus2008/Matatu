import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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

  /// Checks the published update feed for a newer build.
  ///
  /// [showUpToDate] should be `false` for automatic checks (after login): those
  /// stay silent unless there is something to install. The Settings entry keeps
  /// it `true` so the user gets an answer either way.
  Future<void> checkForUpdate({bool showUpToDate = true}) async {
    final updateUrl = Get.find<MainController>().config?.value.updateUrl;
    if (updateUrl == null || updateUrl.trim().isEmpty) {
      _log('no updateUrl configured');
      if (showUpToDate) {
        _info('Updates', 'Update URL is not configured');
      }
      return;
    }

    try {
      final response = await http
          .get(Uri.parse('${updateUrl}update.json'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        _log('update.json returned ${response.statusCode}');
        if (showUpToDate) {
          _info('Updates',
              'Could not check for updates (HTTP ${response.statusCode})');
        }
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      // Accept both the current and the older field names.
      latestVersion.value =
          (data['version'] ?? data['latest_version'] ?? '').toString().trim();
      apkUrl.value = (data['apk_url'] ?? '').toString().trim();
      changelog.value =
          (data['release_notes'] ?? data['changelog'] ?? '').toString().trim();
      final remoteCode =
          int.tryParse((data['version_code'] ?? '').toString()) ?? 0;

      if (latestVersion.value.isEmpty) {
        _log('update.json has no version');
        if (showUpToDate) _info('Updates', 'The update feed has no version');
        return;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentCode = int.tryParse(packageInfo.buildNumber) ?? 0;

      if (!isNewerThan(
          latestVersion.value, remoteCode, currentVersion, currentCode)) {
        _log('up to date ($currentVersion)');
        if (showUpToDate) {
          Get.snackbar(
            'Up to date',
            'You are running the latest version ($currentVersion)',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        }
        return;
      }

      if (apkUrl.value.isEmpty) {
        _log('version ${latestVersion.value} has no apk_url');
        if (showUpToDate) {
          _info('Updates', 'A newer version exists but no download link yet');
        }
        return;
      }

      _log('update available: $currentVersion -> ${latestVersion.value}');
      _showUpdateDialog(currentVersion);
    } catch (e) {
      _log('update check failed: $e');
      if (showUpToDate) {
        Get.snackbar(
          'Updates',
          'Could not check for updates. Check the connection and try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  /// True when the published release is newer than the installed one.
  ///
  /// Version names are compared numerically (so 1.0.16 beats 1.0.9); the build
  /// number is only a tie-breaker, because the two are not always kept in step.
  static bool isNewerThan(
      String remoteName, int remoteCode, String localName, int localCode) {
    final remote = _versionParts(remoteName);
    final local = _versionParts(localName);
    final length = remote.length > local.length ? remote.length : local.length;
    for (var i = 0; i < length; i++) {
      final r = i < remote.length ? remote[i] : 0;
      final l = i < local.length ? local[i] : 0;
      if (r != l) return r > l;
    }
    return remoteCode > localCode;
  }

  static List<int> _versionParts(String version) => version
      .split(RegExp(r'[^0-9]+'))
      .where((p) => p.isNotEmpty)
      .map((p) => int.tryParse(p) ?? 0)
      .toList();

  void _log(String message) {
    if (kDebugMode) debugPrint('[UPDATE] $message');
  }

  void _info(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }

  void _showUpdateDialog(String currentVersion) {
    // Never stack dialogs - an automatic check must not fight the UI.
    if (Get.isDialogOpen ?? false) return;
    Get.dialog(
      AlertDialog(
        title: const Text('Update available'),
        content: Obx(() {
          if (isDownloading.value) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Downloading ${latestVersion.value}... '
                    '${progress.value.toStringAsFixed(0)}%'),
                const SizedBox(height: 10),
                LinearProgressIndicator(value: progress.value / 100),
                const SizedBox(height: 6),
                const Text('Keep the app open until the installer appears.',
                    style: TextStyle(fontSize: 11)),
              ],
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Installed: $currentVersion'),
              Text('Available: ${latestVersion.value}'),
              if (changelog.value.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(changelog.value),
              ],
            ],
          );
        }),
        actions: [
          Obx(() => !isDownloading.value
              ? TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Later'),
                )
              : const SizedBox.shrink()),
          Obx(() => !isDownloading.value
              ? ElevatedButton(
                  onPressed: () => _downloadAndInstallApk(apkUrl.value),
                  child: const Text('Update now'),
                )
              : const SizedBox.shrink()),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _downloadAndInstallApk(String url) async {
    if (url.isEmpty) return;
    try {
      isDownloading.value = true;
      progress.value = 0;

      final dir =
          await getExternalStorageDirectory() ?? await getTemporaryDirectory();
      final apk = File('${dir.path}/CityHoppa-update.apk');
      if (await apk.exists()) await apk.delete();

      await Dio().download(
        url,
        apk.path,
        onReceiveProgress: (received, total) {
          if (total > 0) progress.value = received / total * 100;
        },
        options: Options(receiveTimeout: const Duration(minutes: 5)),
      );

      isDownloading.value = false;
      if (!await apk.exists() || await apk.length() == 0) {
        _info('Update failed', 'The downloaded file is empty');
        return;
      }

      if (Get.isDialogOpen ?? false) Get.back(); // hide the progress dialog
      final result = await OpenFilex.open(apk.path);
      if (result.type != ResultType.done) {
        _info('Update', 'Could not open the installer: ${result.message}');
      }
    } catch (e) {
      isDownloading.value = false;
      _info('Update failed', 'Could not download the update: $e');
    }
  }
}
