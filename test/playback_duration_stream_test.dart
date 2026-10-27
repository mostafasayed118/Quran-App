import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/recitation/playback/just_audio_playback_service.dart';

void main() {
  test('the duration stream drops the replayed seed', () async {
    // just_audio's duration stream is a seeded BehaviorSubject: a new
    // listener receives the previous value first, then any new duration.
    final replayed = Stream<Duration?>.fromIterable(const <Duration?>[
      Duration(minutes: 3),
      Duration(minutes: 5),
    ]);

    final values = await withoutReplaySeed(replayed).toList();

    expect(values, const <Duration?>[Duration(minutes: 5)]);
  });
}
