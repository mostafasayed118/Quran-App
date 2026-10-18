/// Last-read persistence seam (DIP pilot): the reader marker is stored via
/// the drift-backed `LastReadRepository`; cubits depend on this contract.
abstract class LastReadSource {
  Future<void> saveAyahId(int ayahId);

  Future<int?> loadAyahId();
}
