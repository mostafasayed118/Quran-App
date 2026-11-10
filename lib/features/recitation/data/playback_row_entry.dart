import 'package:quran_yahdi/core/db/app_database.dart';

import '../presentation/playback/playback_cubit.dart';
import 'reciter_mapping.dart';

/// Row-typed entry point kept for the frozen recitation doubles: they call
/// `playSurah` with `ReciterRow` literals. The playback surface itself stays
/// row-free and speaks domain entities.
extension PlaybackRowEntry on PlaybackCubit {
  Future<void> playSurah(ReciterRow row, int surahNumber) =>
      playReciter(row.toInfo(), surahNumber);
}
