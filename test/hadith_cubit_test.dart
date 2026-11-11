import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/library/data/hadith_personal.dart';
import 'package:quran_yahdi/features/library/data/pack_downloader.dart';
import 'package:quran_yahdi/features/library/presentation/hadith/hadith_cubit.dart';
import 'package:quran_yahdi/features/library/presentation/hadith/hadith_state.dart';

import 'support/test_db.dart';

final _rows = <(int, String)>[
  for (var i = 1; i <= 25; i++) (i, 'hadith $i'),
];

class _FakeDownloader extends PackDownloader {
  // ignore: use_super_parameters
  _FakeDownloader(AppDatabase db)
      : super(db, libraryRootResolver: () async => Directory.systemTemp);

  @override
  Future<List<InstalledPack>> installedPacks() async => const <InstalledPack>[];

  @override
  Future<(List<(int, String)>, bool)> hadithPage(
    String packId,
    int offset,
    int limit,
  ) async {
    final slice = _rows.skip(offset).take(limit).toList(growable: false);
    return (slice, offset + limit < _rows.length);
  }

  @override
  Future<(List<(int, String)>, bool)> hadithSearch(
    String packId,
    String query, {
    int offset = 0,
    int limit = 20,
  }) async {
    final matches = [
      for (final row in _rows)
        if (row.$2.contains(query)) row,
    ];
    final slice = matches.skip(offset).take(limit).toList(growable: false);
    return (slice, offset + limit < matches.length);
  }

  @override
  Future<List<(int, String)>> hadithByNumbers(
    String packId,
    Set<int> numbers,
  ) async =>
      [
        for (final row in _rows)
          if (numbers.contains(row.$1)) row,
      ];
}

class _Marks implements HadithBookmarkSource {
  Set<int> marks = <int>{};

  @override
  Future<Set<int>> load(String packId) async => marks;

  @override
  Future<void> save(String packId, Set<int> numbers) async {
    marks = numbers;
  }
}

class _Positions implements HadithPositionSource {
  int offset = 0;

  @override
  Future<int> load(String packId) async => offset;

  @override
  Future<void> save(String packId, int value) async {
    offset = value;
  }
}

void main() {
  test('start resumes at the saved offset and pages forward/back', () async {
    final marks = _Marks();
    final positions = _Positions()..offset = 10;
    final cubit = HadithCubit(
      downloader: _FakeDownloader(newTestDb()),
      packId: 'p1',
      bookmarks: marks,
      positions: positions,
    );
    addTearDown(cubit.close);

    await cubit.start();

    final first = cubit.state as HadithReady;
    expect(first.offset, 10);
    expect(first.items.first.$1, 11);
    expect(first.hasMore, isTrue);

    await cubit.next();
    expect((cubit.state as HadithReady).offset, 20);

    await cubit.prev();
    expect((cubit.state as HadithReady).offset, 10);
    expect(positions.offset, 10);
  });

  test('search switches to matching rows and clears back to browse', () async {
    final cubit = HadithCubit(
      downloader: _FakeDownloader(newTestDb()),
      packId: 'p1',
    );
    addTearDown(cubit.close);
    await cubit.start();

    await cubit.search('hadith 2');

    final found = cubit.state as HadithReady;
    expect(found.query, 'hadith 2');
    expect(found.bookmarksOnly, isFalse);
    expect(found.items, isNotEmpty);

    await cubit.clearSearch();
    expect((cubit.state as HadithReady).query, isEmpty);
  });

  test('bookmarks toggle, persist and filter the list', () async {
    final marks = _Marks();
    final cubit = HadithCubit(
      downloader: _FakeDownloader(newTestDb()),
      packId: 'p1',
      bookmarks: marks,
    );
    addTearDown(cubit.close);
    await cubit.start();

    await cubit.toggleBookmark(5);
    expect(marks.marks, {5});
    expect((cubit.state as HadithReady).bookmarked, {5});

    await cubit.showBookmarks();
    final saved = cubit.state as HadithReady;
    expect(saved.bookmarksOnly, isTrue);
    expect(saved.items.map((item) => item.$1), [5]);

    await cubit.toggleBookmark(5);
    expect(marks.marks, isEmpty);
    expect((cubit.state as HadithReady).items, isEmpty);
  });

  test('a failed bookmark save reverts the set', () async {
    final cubit = HadithCubit(
      downloader: _FakeDownloader(newTestDb()),
      packId: 'p1',
      bookmarks: _ThrowingMarks(),
    );
    addTearDown(cubit.close);
    await cubit.start();

    await cubit.toggleBookmark(5);

    expect((cubit.state as HadithReady).bookmarked, isEmpty);
  });

  test('clearing a search returns to the saved browse page', () async {
    final positions = _Positions()..offset = 10;
    final cubit = HadithCubit(
      downloader: _FakeDownloader(newTestDb()),
      packId: 'p1',
      bookmarks: _Marks(),
      positions: positions,
    );
    addTearDown(cubit.close);

    await cubit.start();
    expect((cubit.state as HadithReady).offset, 10);

    await cubit.search('hadith 2');
    expect((cubit.state as HadithReady).query, 'hadith 2');
    expect((cubit.state as HadithReady).offset, 0);

    await cubit.clearSearch();
    expect((cubit.state as HadithReady).offset, 10);
    expect((cubit.state as HadithReady).query, isEmpty);
    expect(positions.offset, 10);

    await cubit.showBookmarks();
    expect((cubit.state as HadithReady).bookmarksOnly, isTrue);
    await cubit.showBrowse();
    expect((cubit.state as HadithReady).offset, 10);
  });
}

class _ThrowingMarks implements HadithBookmarkSource {
  @override
  Future<Set<int>> load(String packId) async => <int>{};

  @override
  Future<void> save(String packId, Set<int> numbers) async {
    throw StateError('save failed');
  }
}
