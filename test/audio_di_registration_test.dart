import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/app/di/injector.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';
import 'package:quran_yahdi/features/recitation/presentation/downloads/downloads_cubit.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/playback_cubit.dart';

void main() {
  test('audio cubits are registered even without a writable audio root',
      () async {
    await configureDependencies();

    expect(getIt.isRegistered<AudioDownloader>(), isTrue);
    expect(getIt.isRegistered<DownloadsCubit>(), isTrue);
    expect(getIt.isRegistered<PlaybackCubit>(), isTrue);
  });
}
