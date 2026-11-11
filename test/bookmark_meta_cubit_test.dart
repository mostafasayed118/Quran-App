import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/features/quran/data/bookmark_meta.dart';
import 'package:quran_yahdi/features/quran/presentation/bookmarks/bookmark_meta_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/bookmarks/bookmark_meta_state.dart';

class _Source implements BookmarkMetaSource {
  _Source([Map<int, BookmarkMetaEntry>? entries])
      : entries = entries ?? <int, BookmarkMetaEntry>{};

  Map<int, BookmarkMetaEntry> entries;
  bool throwOnSave = false;
  int saves = 0;

  @override
  Future<Map<int, BookmarkMetaEntry>> load() async => entries;

  @override
  Future<void> save(Map<int, BookmarkMetaEntry> next) async {
    if (throwOnSave) throw StateError('save failed');
    saves += 1;
    entries = next;
  }
}

void main() {
  test('start loads the stored metadata and exposes the folders', () async {
    final cubit = BookmarkMetaCubit(
      source: _Source({
        9: const BookmarkMetaEntry(folder: 'تفسير', note: 'ملاحظة'),
        8: const BookmarkMetaEntry(folder: 'أذكار'),
      }),
    );
    addTearDown(cubit.close);

    await cubit.start();

    final ready = cubit.state as BookmarkMetaReady;
    expect(ready.folders, ['أذكار', 'تفسير']);
    expect(cubit.entryFor(9)?.note, 'ملاحظة');
    expect(cubit.entryFor(7), isNull);
  });

  test('set stores a trimmed pair and clears it when both fields are empty',
      () async {
    final source = _Source();
    final cubit = BookmarkMetaCubit(source: source);
    addTearDown(cubit.close);
    await cubit.start();

    expect(
      await cubit.set(9, folder: '  تفسير ', note: ' ملاحظة '),
      isTrue,
    );
    expect(
      (cubit.state as BookmarkMetaReady).entries[9],
      const BookmarkMetaEntry(folder: 'تفسير', note: 'ملاحظة'),
    );
    expect(source.entries[9]?.folder, 'تفسير');

    expect(await cubit.set(9, folder: ' ', note: ''), isTrue);
    expect((cubit.state as BookmarkMetaReady).entries, isEmpty);
    expect(source.entries, isEmpty);
  });

  test('remove deletes one entry and is a no-op for an unknown ayah', () async {
    final source = _Source({
      9: const BookmarkMetaEntry(note: 'ملاحظة'),
    });
    final cubit = BookmarkMetaCubit(source: source);
    addTearDown(cubit.close);
    await cubit.start();

    expect(await cubit.remove(9), isTrue);
    expect((cubit.state as BookmarkMetaReady).entries, isEmpty);

    final saves = source.saves;
    expect(await cubit.remove(9), isTrue);
    expect(source.saves, saves);
  });

  test('a failed save reverts the optimistic state', () async {
    final source = _Source();
    final cubit = BookmarkMetaCubit(source: source);
    addTearDown(cubit.close);
    await cubit.start();
    source.throwOnSave = true;

    final saved = await cubit.set(9, folder: 'تفسير', note: '');

    expect(saved, isFalse);
    expect((cubit.state as BookmarkMetaReady).entries, isEmpty);
  });

  test('mutations before the first load are dropped', () async {
    final cubit = BookmarkMetaCubit(source: _Source());
    addTearDown(cubit.close);

    expect(await cubit.set(9, folder: 'تفسير', note: ''), isFalse);
    expect(cubit.state, isA<BookmarkMetaLoading>());
  });

  test('renameFolder moves every bookmark in the folder', () async {
    final source = _Source({
      9: const BookmarkMetaEntry(folder: 'تفسير', note: 'ملاحظة'),
      8: const BookmarkMetaEntry(folder: 'تفسير'),
      7: const BookmarkMetaEntry(folder: 'أذكار'),
    });
    final cubit = BookmarkMetaCubit(source: source);
    addTearDown(cubit.close);
    await cubit.start();

    expect(await cubit.renameFolder('تفسير', 'تدبر'), isTrue);

    final ready = cubit.state as BookmarkMetaReady;
    expect(ready.folders, ['أذكار', 'تدبر']);
    expect(ready.entries[9]?.note, 'ملاحظة');
    expect(source.entries[8]?.folder, 'تدبر');
  });

  test('deleteFolder drops the label and keeps the notes', () async {
    final source = _Source({
      9: const BookmarkMetaEntry(folder: 'تفسير', note: 'ملاحظة'),
      8: const BookmarkMetaEntry(folder: 'أذكار'),
    });
    final cubit = BookmarkMetaCubit(source: source);
    addTearDown(cubit.close);
    await cubit.start();

    expect(await cubit.deleteFolder('تفسير'), isTrue);

    final ready = cubit.state as BookmarkMetaReady;
    expect(ready.folders, ['أذكار']);
    expect(ready.entries[9]?.folder, isEmpty);
    expect(ready.entries[9]?.note, 'ملاحظة');
  });

  test('a failed folder rename reverts to the previous map', () async {
    final source = _Source({
      9: const BookmarkMetaEntry(folder: 'تفسير'),
    })
      ..throwOnSave = true;
    final cubit = BookmarkMetaCubit(source: source);
    addTearDown(cubit.close);
    await cubit.start();

    expect(await cubit.renameFolder('تفسير', 'تدبر'), isFalse);
    expect((cubit.state as BookmarkMetaReady).folders, ['تفسير']);
  });
}
