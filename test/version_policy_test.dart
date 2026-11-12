import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/domain/version_policy.dart';

void main() {
  group('AppVersion.parse', () {
    test('parses a plain x.y.z version', () {
      expect(AppVersion.parse('1.2.3'), const AppVersion(1, 2, 3));
    });

    test('parses a version with a build number', () {
      expect(AppVersion.parse('1.2.3+42'), const AppVersion(1, 2, 3, 42));
    });

    test('tolerates surrounding whitespace', () {
      expect(AppVersion.parse('  1.2.3  '), const AppVersion(1, 2, 3));
    });

    test('rejects too few parts', () {
      expect(AppVersion.parse('1.2'), isNull);
      expect(AppVersion.parse('1'), isNull);
    });

    test('rejects non-numeric fields', () {
      expect(AppVersion.parse('a.b.c'), isNull);
      expect(AppVersion.parse('1.x.3'), isNull);
    });

    test('rejects a prerelease tag — the app never ships one', () {
      expect(AppVersion.parse('1.2.3-rc1'), isNull);
    });

    test('rejects empty and null input', () {
      expect(AppVersion.parse(''), isNull);
      expect(AppVersion.parse(null), isNull);
    });

    test('rejects too many parts', () {
      expect(AppVersion.parse('1.2.3.4'), isNull);
    });
  });

  group('AppVersion ordering', () {
    test('1.10.0 sorts above 1.9.0 (not a string comparison)', () {
      expect(
        const AppVersion(1, 10, 0).compareTo(const AppVersion(1, 9, 0)),
        isPositive,
      );
      expect(
        const AppVersion(1, 9, 0).compareTo(const AppVersion(1, 10, 0)),
        isNegative,
      );
    });

    test('build number breaks a tie on name', () {
      expect(
        const AppVersion(1, 0, 0, 5).compareTo(const AppVersion(1, 0, 0, 4)),
        isPositive,
      );
      expect(
        const AppVersion(1, 0, 0, 4).compareTo(const AppVersion(1, 0, 0, 5)),
        isNegative,
      );
    });

    test('name dominates build', () {
      expect(
        AppVersion.parse('2.0.0+1')!.compareTo(AppVersion.parse('1.9.9+99')!),
        isPositive,
      );
    });

    test('equal versions compare zero', () {
      expect(
        AppVersion.parse('1.2.3+4')!.compareTo(AppVersion.parse('1.2.3+4')!),
        0,
      );
    });

    test('equality holds field-by-field', () {
      expect(AppVersion.parse('1.2.3+4'), AppVersion.parse('1.2.3+4'));
      expect(AppVersion.parse('1.2.3'), isNot(AppVersion.parse('1.2.3+1')));
    });
  });

  group('VersionPolicy.fromJson', () {
    test('accepts a fully populated policy', () {
      final policy = VersionPolicy.fromJson({
        'min_supported': '1.2.0',
        'latest': '1.4.0',
      });
      expect(policy, isNotNull);
      expect(policy!.minSupported, const AppVersion(1, 2, 0));
      expect(policy.latest, const AppVersion(1, 4, 0));
    });

    test('rejects a missing min_supported', () {
      expect(VersionPolicy.fromJson({'latest': '1.0.0'}), isNull);
    });

    test('rejects an unparsable latest', () {
      expect(
        VersionPolicy.fromJson({'min_supported': '1.0.0', 'latest': 'soon'}),
        isNull,
      );
    });

    test('rejects latest below min_supported (fail-open, never enforced)', () {
      expect(
        VersionPolicy.fromJson({'min_supported': '1.9.0', 'latest': '1.0.0'}),
        isNull,
      );
    });

    test('rejects a non-map payload', () {
      expect(VersionPolicy.fromJson('nope'), isNull);
      expect(VersionPolicy.fromJson([1, 2]), isNull);
      expect(VersionPolicy.fromJson(null), isNull);
    });
  });

  group('isPlausibleFor', () {
    test('accepts a same-major minor jump within the window', () {
      const policy = VersionPolicy(
        minSupported: AppVersion(1, 2, 0),
        latest: AppVersion(1, 4, 0),
      );
      expect(policy.isPlausibleFor(const AppVersion(1, 0, 0)), isTrue);
    });

    test('rejects a same-major jump beyond the window', () {
      const policy = VersionPolicy(
        minSupported: AppVersion(1, 10, 0),
        latest: AppVersion(1, 10, 0),
      );
      expect(policy.isPlausibleFor(const AppVersion(1, 0, 0)), isFalse);
    });

    test('accepts a one-major upgrade', () {
      const policy = VersionPolicy(
        minSupported: AppVersion(2, 0, 0),
        latest: AppVersion(2, 0, 0),
      );
      expect(policy.isPlausibleFor(const AppVersion(1, 0, 0)), isTrue);
    });

    test('rejects an implausible two-major jump', () {
      const policy = VersionPolicy(
        minSupported: AppVersion(99, 0, 0),
        latest: AppVersion(99, 0, 0),
      );
      expect(policy.isPlausibleFor(const AppVersion(1, 0, 0)), isFalse);
    });

    test('allows an older minimum (no lockout risk)', () {
      const policy = VersionPolicy(
        minSupported: AppVersion(0, 9, 0),
        latest: AppVersion(1, 0, 0),
      );
      expect(policy.isPlausibleFor(const AppVersion(1, 0, 0)), isTrue);
    });
  });

  group('verdicts', () {
    const policy = VersionPolicy(
      minSupported: AppVersion(1, 2, 0),
      latest: AppVersion(1, 4, 0),
    );

    test('below the minimum → updateRequired', () {
      expect(policy.verdictFor(const AppVersion(1, 1, 9)),
          VersionVerdict.updateRequired);
      expect(policy.verdictFor(const AppVersion(0, 9, 0)),
          VersionVerdict.updateRequired);
    });

    test('at the minimum but behind latest → updateRecommended', () {
      expect(policy.verdictFor(const AppVersion(1, 2, 0)),
          VersionVerdict.updateRecommended);
      expect(policy.verdictFor(const AppVersion(1, 3, 9)),
          VersionVerdict.updateRecommended);
    });

    test('at or above latest → upToDate', () {
      expect(policy.verdictFor(const AppVersion(1, 4, 0)),
          VersionVerdict.upToDate);
      expect(policy.verdictFor(const AppVersion(2, 0, 0)),
          VersionVerdict.upToDate);
    });
  });
}
