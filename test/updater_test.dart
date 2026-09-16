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
}
