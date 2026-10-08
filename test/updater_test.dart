import 'package:flutter_test/flutter_test.dart';
import 'package:t_matatu/utils/updater.dart';

/// The self-update prompt only appears when the published version is strictly
/// newer, so these comparisons decide whether the feature works at all.
void main() {
  group('UpdateController.isNewerThan', () {
    test('detects a newer release (1.0.9 -> 1.0.16)', () {
      expect(UpdateController.isNewerThan('1.0.16', 13, '1.0.9', 14), isTrue);
    });

    test('same version and code is not newer', () {
      expect(UpdateController.isNewerThan('1.0.16', 13, '1.0.16', 13), isFalse);
    });

    test('same version but higher build code is newer', () {
      expect(UpdateController.isNewerThan('1.0.16', 14, '1.0.16', 13), isTrue);
    });

    test('same version but higher local build code is not newer', () {
      expect(UpdateController.isNewerThan('1.0.16', 12, '1.0.16', 13), isFalse);
    });

    test('older published release is not newer', () {
      expect(UpdateController.isNewerThan('1.0.5', 99, '1.0.9', 1), isFalse);
    });

    test('major/minor bumps win over the build code', () {
      expect(UpdateController.isNewerThan('1.1', 1, '1.0.9', 50), isTrue);
      expect(UpdateController.isNewerThan('2.0.0', 1, '1.99.99', 50), isTrue);
    });

    test('missing trailing components are treated as zero', () {
      expect(UpdateController.isNewerThan('1.0', 0, '1.0.0', 0), isFalse);
      expect(UpdateController.isNewerThan('1.0.1', 0, '1.0', 0), isTrue);
    });

    test('suffixed versions are compared on their numbers', () {
      expect(
          UpdateController.isNewerThan('1.0.17-beta', 0, '1.0.16', 0), isTrue);
    });

    test('an empty published version never counts as newer', () {
      expect(UpdateController.isNewerThan('', 0, '1.0.9', 0), isFalse);
    });
  });

  /// The feed publishes one APK per ABI family and Android rejects
  /// cross-family installs as a downgrade, so each device must download the
  /// build that belongs to the family it is already running.
  group('UpdateController.apkFor', () {
    final feed = <String, dynamic>{
      'apk_url': 'https://feed/CityHoppa-v1.0.37.apk',
      'sha256': 'AAAA1111',
      'apk_url_32': 'https://feed/CityHoppa-v1.0.37-32bit.apk',
      'sha256_32': 'BBBB2222',
      'apk_url_x64': 'https://feed/CityHoppa-v1.0.37-x64.apk',
      'sha256_x64': 'CCCC3333',
    };

    test('64-bit ARM devices take the main APK', () {
      final pick = UpdateController.apkFor(feed);
      expect(pick.url, 'https://feed/CityHoppa-v1.0.37.apk');
      expect(pick.sha256, 'aaaa1111');
    });

    test('32-bit ARM devices take the 32-bit APK', () {
      final pick = UpdateController.apkFor(feed, abi: 'arm32');
      expect(pick.url, 'https://feed/CityHoppa-v1.0.37-32bit.apk');
      expect(pick.sha256, 'bbbb2222');
    });

    test('x86_64 devices take the x64 APK', () {
      final pick = UpdateController.apkFor(feed, abi: 'x64');
      expect(pick.url, 'https://feed/CityHoppa-v1.0.37-x64.apk');
      expect(pick.sha256, 'cccc3333');
    });

    test('falls back to the main APK when the feed has no 32-bit build', () {
      final no32 = Map<String, dynamic>.from(feed)
        ..remove('apk_url_32')
        ..remove('sha256_32');
      final pick = UpdateController.apkFor(no32, abi: 'arm32');
      expect(pick.url, 'https://feed/CityHoppa-v1.0.37.apk');
      expect(pick.sha256, 'aaaa1111');
    });

    test('an empty extra url also falls back to the main APK', () {
      final blank = Map<String, dynamic>.from(feed)..['apk_url_32'] = '';
      final pick = UpdateController.apkFor(blank, abi: 'arm32');
      expect(pick.url, 'https://feed/CityHoppa-v1.0.37.apk');
    });

    test('missing hashes come out empty (length check only)', () {
      final pick = UpdateController.apkFor(
          <String, dynamic>{'apk_url': 'https://feed/x.apk'});
      expect(pick.sha256, '');
    });
  });

  /// Guards against the "There was a problem while parsing the package"
  /// failure: a file left behind by an interrupted download must never be
  /// treated as ready for the installer.
  group('UpdateController.looksComplete', () {
    test('a full file matches the expected length', () {
      expect(
          UpdateController.looksComplete(
              actualLength: 22061728, expectedLength: 22061728),
          isTrue);
    });

    test('a partial file is not complete', () {
      expect(
          UpdateController.looksComplete(
              actualLength: 5000000, expectedLength: 22061728),
          isFalse);
    });

    test('a longer file is not complete', () {
      expect(
          UpdateController.looksComplete(
              actualLength: 30000000, expectedLength: 22061728),
          isFalse);
    });

    test('the published sha256 wins over the length', () {
      expect(
          UpdateController.looksComplete(
              actualLength: 100,
              expectedLength: 100,
              expectedSha256: 'D39C4447',
              actualSha256: 'd39c4447'),
          isTrue);
      expect(
          UpdateController.looksComplete(
              actualLength: 100,
              expectedLength: 100,
              expectedSha256: 'D39C4447',
              actualSha256: 'FFFFFFFF'),
          isFalse);
    });

    test('without server data the file is trusted (offline retry)', () {
      expect(UpdateController.looksComplete(actualLength: 42), isTrue);
    });
  });
}
