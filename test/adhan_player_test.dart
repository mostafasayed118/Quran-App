import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/domain/adhan_player.dart';
import 'package:quran_yahdi/core/domain/media_playback_control.dart';
import 'package:quran_yahdi/features/notifications/data/just_audio_adhan_player.dart';

class _FakeControl implements MediaPlaybackControl {
  _FakeControl(this.log);

  final List<String> log;
  bool failNext = false;

  @override
  Future<void> stopForAdhan() async => log.add('control:stop');

  @override
  Future<void> playAdhan(
    String assetPath, {
    required String id,
    required String title,
  }) async {
    log.add('control:play:$assetPath');
    if (failNext) throw StateError('missing asset');
  }

  @override
  Stream<void> get adhanCompleted => const Stream<void>.empty();
}

void main() {
  late List<String> log;
  late _FakeControl control;

  JustAudioAdhanPlayer build({
    Future<bool> Function()? ready,
    Duration readyTimeout = const Duration(seconds: 2),
  }) {
    log = <String>[];
    control = _FakeControl(log);
    return JustAudioAdhanPlayer(
      ready: ready ?? () async => true,
      control: control,
      readyTimeout: readyTimeout,
    );
  }

  test('playing the adhan stops recitation first', () async {
    final player = build();

    await player.play('khushu');

    expect(log, [
      'control:stop',
      'control:play:assets/audio/adhan/khushu.m4a',
    ]);
  });

  test('preview plays the clip, not the full adhan', () async {
    final player = build();

    await player.preview('khushu');

    expect(log.last, 'control:play:assets/audio/adhan/clips/khushu_clip.m4a');
  });

  test('a second preview replaces the first instead of stacking', () async {
    final player = build();

    await player.preview('khushu');
    await player.preview('omar_hisham');

    // One stop per preview: the first audition is silenced before the second
    // starts, so the two never mix.
    expect(log.where((entry) => entry == 'control:stop'), hasLength(2));
    expect(
      log.last,
      'control:play:assets/audio/adhan/clips/omar_hisham_clip.m4a',
    );
  });

  test('a request made before the plugin is ready waits, and is not dropped',
      () async {
    final gate = Completer<bool>();
    final player = build(ready: () => gate.future);

    final pending = player.play('khushu');
    await Future<void>.delayed(Duration.zero);
    expect(log, isEmpty, reason: 'must not touch audio before readiness');

    gate.complete(true);
    await pending;

    expect(log.last, 'control:play:assets/audio/adhan/khushu.m4a');
  });

  test('a plugin that hangs does not queue the request forever', () async {
    // `BackgroundInitGuard.ready` only completes when the plugin returns, so a
    // hanging plugin would otherwise leave the request pending for the whole
    // session — the exact case Review Focus #5 names.
    final player = build(
      ready: () => Completer<bool>().future,
      readyTimeout: const Duration(milliseconds: 20),
    );

    await player.play('khushu').timeout(const Duration(seconds: 2));

    expect(log, isEmpty);
    expect(player.stateNow.status, AdhanPlaybackStatus.idle);
  });

  test('a missing asset fails open: logs, returns to idle, never throws',
      () async {
    final player = build();
    control.failNext = true;

    await expectLater(player.play('khushu'), completes);

    expect(player.stateNow.status, AdhanPlaybackStatus.idle);
  });

  test('a plugin that never became ready leaves the player idle', () async {
    final player = build(ready: () async => false);

    await player.play('khushu');

    expect(log, isEmpty);
    expect(player.stateNow.status, AdhanPlaybackStatus.idle);
  });
}
