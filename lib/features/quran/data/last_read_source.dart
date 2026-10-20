import '../../../core/domain/last_read.dart';

/// Last-read persistence seam (DIP pilot): the reader marker is stored via
/// the drift-backed `LastReadRepository`; cubits depend on this contract.
abstract class LastReadSource implements LastReadMarker {
  /// Stores [ayahId] as the last-read position.
  Future<void> saveAyahId(int ayahId);

  @override
  Future<int?> loadAyahId();
}
