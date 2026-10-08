import 'dart:ffi';

/// Which extra build this device should pull from the update feed.
///
/// The feed publishes one APK per ABI family and Android rejects switching
/// families as a version downgrade (arm32 = 1000 + build, arm64 = 2000 +
/// build, x64 = 4000 + build), so a device must stay in the family it is
/// already running:
///   'arm32' - 32-bit ARM install (armeabi-v7a)
///   'x64'   - 64-bit x86 install (emulators)
///   ''      - everything else uses the main (arm64) build
String get runningAbiKey {
  final abi = Abi.current();
  if (abi == Abi.androidArm) return 'arm32';
  if (abi == Abi.androidX64) return 'x64';
  return '';
}
