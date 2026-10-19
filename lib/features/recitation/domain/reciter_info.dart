/// A reciter catalog entry, decoupled from the drift row (DIP rollout).
///
/// Field names mirror the `ReciterRow` row so presentation reads
/// (`reciterName`, `moshafName`, `surahTotal`, ...) keep compiling unchanged.
class ReciterInfo {
  const ReciterInfo({
    required this.id,
    required this.reciterName,
    required this.moshafName,
    required this.server,
    required this.surahList,
    required this.surahTotal,
  });

  final String id;
  final String reciterName;
  final String moshafName;
  final String server;
  final String surahList;
  final int surahTotal;
}
