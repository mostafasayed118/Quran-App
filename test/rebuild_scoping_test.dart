import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/qibla/presentation/qibla_screen.dart';
import 'package:quran_yahdi/features/qibla/presentation/qibla_state.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/mini_player_bar.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/playback_state.dart';

const cairo = City(
  id: 'cairo',
  nameAr: 'القاهرة',
  nameEn: 'Cairo',
  lat: 30.0444,
  lng: 31.2357,
);

const giza = City(
  id: 'giza',
  nameAr: 'الجيزة',
  nameEn: 'Giza',
  lat: 30.0131,
  lng: 31.2089,
);

void main() {
  group('miniPlayerShellShouldRebuild', () {
    PlaybackState playing({
      Duration position = Duration.zero,
      Duration duration = const Duration(minutes: 6),
      String reciterName = 'عبدالباسط عبدالصمد',
      int surahNumber = 1,
    }) =>
        PlaybackState.playing(
          reciterName: reciterName,
          surahNumber: surahNumber,
          position: position,
          duration: duration,
        );

    test('a position-only tick does not rebuild the shell', () {
      expect(
        miniPlayerShellShouldRebuild(
          playing(position: const Duration(seconds: 1)),
          playing(position: const Duration(seconds: 2)),
        ),
        isFalse,
      );
    });

    test('identical states do not rebuild the shell', () {
      expect(miniPlayerShellShouldRebuild(playing(), playing()), isFalse);
      expect(
        miniPlayerShellShouldRebuild(
          const PlaybackState.initial(),
          const PlaybackState.initial(),
        ),
        isFalse,
      );
    });

    test('a track change rebuilds the shell', () {
      expect(
        miniPlayerShellShouldRebuild(playing(), playing(surahNumber: 2)),
        isTrue,
      );
      expect(
        miniPlayerShellShouldRebuild(
          playing(),
          playing(reciterName: 'محمود خليل الحصري'),
        ),
        isTrue,
      );
    });

    test('a status change rebuilds the shell', () {
      expect(
        miniPlayerShellShouldRebuild(
          playing(),
          const PlaybackState.paused(
            reciterName: 'عبدالباسط عبدالصمد',
            surahNumber: 1,
          ),
        ),
        isTrue,
      );
    });

    test('a duration change rebuilds the shell', () {
      expect(
        miniPlayerShellShouldRebuild(
          playing(),
          playing(duration: const Duration(minutes: 7)),
        ),
        isTrue,
      );
    });

    test('a failure-kind change rebuilds; an identical failure does not', () {
      expect(
        miniPlayerShellShouldRebuild(
          const PlaybackState.failed(kind: PlaybackFailureKind.network),
          const PlaybackState.failed(
            kind: PlaybackFailureKind.backgroundUnavailable,
          ),
        ),
        isTrue,
      );
      expect(
        miniPlayerShellShouldRebuild(
          const PlaybackState.failed(kind: PlaybackFailureKind.network),
          const PlaybackState.failed(kind: PlaybackFailureKind.network),
        ),
        isFalse,
      );
    });
  });

  group('qiblaBodyShouldRebuild', () {
    QiblaState ready({
      City? city = cairo,
      double? bearing = 137.2,
      double? heading = 10.0,
      bool compassUnavailable = false,
    }) =>
        QiblaState.ready(
          city: city,
          bearing: bearing,
          heading: heading,
          compassUnavailable: compassUnavailable,
        );

    test('sub-degree heading jitter does not rebuild the body', () {
      expect(
        qiblaBodyShouldRebuild(
          ready(heading: 10.2),
          ready(heading: 10.4),
        ),
        isFalse,
      );
    });

    test('a rounded heading crossing rebuilds the body', () {
      expect(
        qiblaBodyShouldRebuild(
          ready(heading: 10.4),
          ready(heading: 10.6),
        ),
        isTrue,
      );
      expect(
        qiblaBodyShouldRebuild(
          ready(heading: 10.0),
          ready(heading: 11.0),
        ),
        isTrue,
      );
    });

    test('a heading appearing or disappearing rebuilds the body', () {
      expect(
        qiblaBodyShouldRebuild(ready(heading: null), ready(heading: 0.2)),
        isTrue,
      );
      expect(
        qiblaBodyShouldRebuild(ready(heading: 0.2), ready(heading: null)),
        isTrue,
      );
    });

    test('identical states do not rebuild the body', () {
      expect(qiblaBodyShouldRebuild(ready(), ready()), isFalse);
      expect(
        qiblaBodyShouldRebuild(
          const QiblaState.ready(),
          const QiblaState.ready(),
        ),
        isFalse,
      );
    });

    test('city, bearing, or availability changes rebuild the body', () {
      expect(qiblaBodyShouldRebuild(ready(), ready(city: giza)), isTrue);
      expect(qiblaBodyShouldRebuild(ready(), ready(bearing: 140.0)), isTrue);
      expect(
        qiblaBodyShouldRebuild(
          ready(),
          ready(compassUnavailable: true),
        ),
        isTrue,
      );
    });
  });
}
