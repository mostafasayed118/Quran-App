import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  test('manifest requests coarse location only and blocks cleartext', () {
    final manifest = _read('android/app/src/main/AndroidManifest.xml');
    expect(manifest, contains('ACCESS_COARSE_LOCATION'));
    expect(manifest, isNot(contains('ACCESS_FINE_LOCATION')));
    expect(manifest, contains('android:usesCleartextTraffic="false"'));
    expect(manifest, contains('android:label="@string/app_name"'));
    expect(manifest, contains('android:localeConfig="@xml/locales_config"'));
  });

  test('SDK levels and debug identity are pinned', () {
    final gradle = _read('android/app/build.gradle');
    expect(gradle, contains('compileSdk = 36'));
    expect(gradle, contains('minSdk = 24'));
    expect(gradle, contains('targetSdk = 36'));
    expect(gradle, contains('applicationIdSuffix = ".debug"'));
    expect(_read('.fvmrc'), contains('"flutter": "3.47.5"'));
  });

  test('data extraction excludes the file domain from both paths', () {
    final rules =
        _read('android/app/src/main/res/xml/data_extraction_rules.xml');
    expect(RegExp('domain="file"').allMatches(rules).length, 2);
  });

  test('CI is least-privilege, gated, SHA-pinned, and honestly named', () {
    final ci = _read('.github/workflows/ci.yml');
    expect(ci, contains('permissions:'));
    expect(ci, contains('contents: read'));
    expect(ci, contains('needs: [analyze-test]'));
    expect(ci, contains('debug-signed-apk'));
    expect(ci, contains('debug-signed-aab'));
    expect(ci, isNot(contains('name: app-release-apk')));
    expect(ci, isNot(contains('name: app-release-aab')));
    expect(ci, isNot(contains('actions/checkout@v4')));
    expect(ci, isNot(contains('subosito/flutter-action@v2')));
    expect(ci, isNot(contains('actions/upload-artifact@v4')));
    expect(RegExp(r'actions/checkout@[0-9a-f]{40}').hasMatch(ci), isTrue);
    expect(
        RegExp(r'subosito/flutter-action@[0-9a-f]{40}').hasMatch(ci), isTrue);
    expect(
        RegExp(r'actions/upload-artifact@[0-9a-f]{40}').hasMatch(ci), isTrue);
  });

  test('Gradle wrapper is checksum-pinned and not ignored', () {
    final props = _read('android/gradle/wrapper/gradle-wrapper.properties');
    expect(
      props,
      contains(
        'distributionSha256Sum='
        '17f277867f6914d61b1aa02efab1ba7bb439ad652ca485cd8ca6842fccec6e43',
      ),
    );
    final ignore = _read('android/.gitignore');
    expect(ignore, isNot(contains('gradle-wrapper.jar')));
    expect(ignore, isNot(contains('/gradlew')));
  });
}
