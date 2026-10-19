import '../../../core/db/app_database.dart';
import '../domain/reciter_info.dart';
import 'reciter_repository.dart';

/// Drift row → domain entity mapping (DIP rollout).
///
/// The frozen test doubles pin the repository signatures to drift rows, so
/// the data layer keeps returning them; the presentation boundary maps rows
/// to entities here instead.
extension ReciterRowMapping on ReciterRow {
  ReciterInfo toInfo() => ReciterInfo(
        id: id,
        reciterName: reciterName,
        moshafName: moshafName,
        server: server,
        surahList: surahList,
        surahTotal: surahTotal,
      );
}

/// Featured predicate for mapped entities: mirrors [isFeaturedReciterRow]
/// (the row twin stays in `reciter_repository.dart`) against the same pinned
/// `featuredReciterIds` contract.
bool isFeaturedReciterInfo(ReciterInfo info) {
  final leadingId = int.tryParse(info.id.split('-').first);
  return leadingId != null && featuredReciterIds.contains(leadingId);
}
