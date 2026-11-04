import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/presentation/bookmarks/bookmarks_cubit.dart';

import 'support/test_db.dart';

/// Repository seam whose delete always fails, to pin the reported result.
class _ThrowingDelete extends AyahRepository {
  _ThrowingDelete(super.db);

  @override
  Future<void> deleteBookmark(int ayahId) async {
    throw StateError('bookmark delete failed');
  }
}

void main() {
  test('a failed delete is reported, not thrown at the screen', () async {
    final cubit = BookmarksCubit(_ThrowingDelete(newTestDb()));
    addTearDown(cubit.close);

    expect(await cubit.remove(9), isFalse);
  });

  test('a landed delete reports true', () async {
    final repo = AyahRepository(newTestDb());
    final cubit = BookmarksCubit(repo);
    addTearDown(cubit.close);

    expect(await cubit.remove(9), isTrue);
  });
}
