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

  /// True when the published release must be installed before the app can be
  /// used. Releases are mandatory unless the feed publishes "mandatory": false.
  var isMandatory = true.obs;

  /// Message from the last failed download or install attempt; shown inside the
  /// dialog so a failed required update can be retried.
  var downloadError = "".obs;

  /// True once the new build sits on disk and only needs installing — the
  /// silent automatic check fills this before it asks the user.
  var apkReady = false.obs;

  /// Release the user postponed this session; the automatic check stays quiet
  /// about it until the app restarts or a newer release is published.
  String? _postponedVersion;

  /// Guards against two automatic ask-loops running at once.
  bool _askingUser = false;

  /// Context of the update dialog itself, so it can always be closed through
  /// the navigator that owns it (see [closeUpdateDialog]).
  BuildContext? _dialogContext;
  bool _dialogOpen = false;

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
      // Required by default: only a release that explicitly says
      // "mandatory": false may be postponed.
      final mandatoryRaw = data['mandatory'];
      isMandatory.value = mandatoryRaw == null
          ? true
          : (mandatoryRaw is bool
              ? mandatoryRaw
              : mandatoryRaw.toString().toLowerCase() != 'false');
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

      if (showUpToDate) {
        // Manual check: show the dialog at once so the download is visible
        // and the user controls when it starts.
        _showUpdateDialog(currentVersion);
        return;
      }

      // Automatic check: fetch the build quietly first, then ask the user.
      await _fetchThenAsk(currentVersion);
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

  /// Returns true when the dialog was shown; false when another dialog already
  /// owns the screen (the caller may retry later).
  bool _showUpdateDialog(String currentVersion) {
    // Never stack dialogs - an automatic check must not fight the UI.
    if (_dialogOpen || (Get.isDialogOpen ?? false)) return false;

    final hostContext = Get.context ?? Get.key.currentContext;
    if (hostContext == null) {
      _log('no context available to show the update dialog');
      return false;
    }

    _dialogOpen = true;
    showDialog<void>(
      context: hostContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        _dialogContext = dialogContext;
        return PopScope(
          // A required update must survive the back button; an optional one
          // can be dismissed like any other dialog.
          canPop: !isMandatory.value,
          child: AlertDialog(
            title: Obx(() => Text(
                isMandatory.value ? 'Update required' : 'Update available')),
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
                    const Text(
                        'Downloading in the background - you can keep using '
                        'the app.',
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
                  if (apkReady.value) ...[
                    const SizedBox(height: 12),
                    const Text(
                        'The update has been downloaded - install it now?',
                        style: TextStyle(fontSize: 12)),
                  ],
                  if (isMandatory.value) ...[
                    const SizedBox(height: 12),
                    const Text(
                        'This update has to be installed before the app can be '
                        'used again.',
                        style: TextStyle(fontSize: 12)),
                  ],
                  if (downloadError.value.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(downloadError.value,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.red)),
                    const SizedBox(height: 4),
                    const Text(
                        'If the installer does not open, allow this app to '
                        'install unknown apps in Android settings.',
                        style:
                            TextStyle(fontSize: 11, color: Color(0xFF5B5F61))),
                  ],
                ],
              );
            }),
            actions: [
              Obx(() => !isDownloading.value && !isMandatory.value
                  ? TextButton(
                      onPressed: postponeUpdate,
                      child: const Text('Later'),
                    )
                  : const SizedBox.shrink()),
              Obx(() => !isDownloading.value
                  ? ElevatedButton(
                      onPressed: () => _downloadAndInstallApk(apkUrl.value),
                      child: Text(
                        downloadError.value.isNotEmpty
                            ? 'Try again'
                            : (apkReady.value ? 'Install now' : 'Update now'),
                      ),
                    )
                  : const SizedBox.shrink()),
            ],
          ),
        );
      },
    ).whenComplete(() {
      _dialogOpen = false;
      _dialogContext = null;
    });
    return true;
  }

  /// Closes the update dialog through the navigator that owns it.
  ///
  /// Get.back() resolves the route through GetX's own bookkeeping, which is not
  /// reliable here: the automatic check runs two seconds after login, while
  /// GetX is still settling the Get.off that replaced the login page, so
  /// Get.back() popped the wrong route and the dialog's buttons looked dead.
  void closeUpdateDialog() {
    final context = _dialogContext;
    if (context != null && context.mounted) {
      Navigator.of(context).pop();
      return;
    }
    if (Get.isDialogOpen ?? false) Get.back();
  }

  /// The user chose "Later": stop asking about this release until the app is
  /// restarted or a newer one is published.
  void postponeUpdate() {
    _postponedVersion = latestVersion.value;
    closeUpdateDialog();
  }

  /// Automatic path: download the new build without any prompt, then ask the
  /// user whether to install it. When another dialog owns the screen the ask
  /// is retried until the UI is free again.
  Future<void> _fetchThenAsk(String currentVersion) async {
    if (_postponedVersion == latestVersion.value) return;

    if (!isDownloading.value && !apkReady.value) {
      await _downloadApk();
    }
    if (_postponedVersion == latestVersion.value) return;
    if (!apkReady.value) {
      _log('silent download failed: ${downloadError.value}');
    }

    if (_askingUser) return;
    _askingUser = true;
    try {
      for (var attempt = 0; attempt < 30; attempt++) {
        if (_postponedVersion == latestVersion.value) return;
        if (_showUpdateDialog(currentVersion)) return;
        await Future.delayed(const Duration(seconds: 10));
      }
    } finally {
      _askingUser = false;
    }
  }

  /// The file the current release downloads to. One file per version, so
  /// retrying after a cancelled install does not download everything again.
  Future<File?> _apkFile() async {
    try {
      final dir =
          await getExternalStorageDirectory() ?? await getTemporaryDirectory();
      return File('${dir.path}/CityHoppa-${latestVersion.value}.apk');
    } catch (_) {
      return null;
    }
  }

  /// Downloads the current release's APK without showing anything. Returns
  /// true when the file is on disk and ready to install.
  Future<bool> _downloadApk() async {
    final apk = await _apkFile();
    if (apk == null) {
      apkReady.value = false;
      downloadError.value = 'Storage is not available for the update.';
      return false;
    }
    if (await apk.exists() && await apk.length() > 0) {
      apkReady.value = true;
      return true;
    }

    apkReady.value = false;
    downloadError.value = '';
    isDownloading.value = true;
    progress.value = 0;
    try {
      await Dio().download(
        apkUrl.value,
        apk.path,
        onReceiveProgress: (received, total) {
          if (total > 0) progress.value = received / total * 100;
        },
        options: Options(receiveTimeout: const Duration(minutes: 5)),
      );

      if (!await apk.exists() || await apk.length() == 0) {
        downloadError.value = 'The downloaded file is empty.';
        return false;
      }
      apkReady.value = true;
      return true;
    } catch (e) {
      downloadError.value = 'Could not download the update: $e';
      return false;
    } finally {
      isDownloading.value = false;
    }
  }

  /// Opens the system installer for the downloaded APK, then checks again: if
  /// the app is still on the old version (installer cancelled or never opened)
  /// the update has to come back - a required update cannot be side-stepped by
  /// backing out of the installer.
  Future<void> _installApk() async {
    final apk = await _apkFile();
    if (apk == null || !await apk.exists() || await apk.length() == 0) {
      downloadError.value = 'The update file is missing.';
      return;
    }

    // Not guarded by Get.isDialogOpen: this dialog is pushed with
    // showDialog, which GetX does not track.
    closeUpdateDialog();
    final result = await OpenFilex.open(apk.path);
    if (result.type != ResultType.done) {
      downloadError.value = 'Could not open the installer: ${result.message}.';
    }

    await checkForUpdate(showUpToDate: false);
  }

  /// Dialog button: make sure the APK is downloaded, then open the installer.
  Future<void> _downloadAndInstallApk(String url) async {
    if (url.isEmpty || isDownloading.value) return;
    final ready = await _downloadApk();
    if (!ready) return; // downloadError is set; the dialog offers "Try again"
    await _installApk();
  }
}
