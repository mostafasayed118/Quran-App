import '../domain/reciter_info.dart';

/// Domain-typed twin of [ReciterSource]: the playback surface speaks entities,
/// never drift rows.
abstract class ReciterInfoSource {
  /// The user's selected reciter, or the first featured one when nothing is
  /// selected; null when the catalog is empty.
  Future<ReciterInfo?> defaultReciter();
}
