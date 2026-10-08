// Fallback for platforms where dart:ffi is unavailable (web preview builds).
// The released app is Android-only, where running_abi_ffi.dart is used.

/// Which extra build this device should pull from the update feed:
/// 'arm32' / 'x64' / '' (the main arm64 build).
String get runningAbiKey => '';
