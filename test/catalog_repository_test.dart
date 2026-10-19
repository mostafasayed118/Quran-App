import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/library/data/catalog_repository.dart';
import 'package:quran_yahdi/features/library/data/library_catalog.dart';

List<Map<String, dynamic>> fixturePacks() => [
      {
        'id': 'ar-tafsir-muyassar',
        'kind': 'tafsir',
        'language': 'ar',
        'titleAr': 'التفسير الميسر',
        'titleEn': 'At-Tafsir Al-Muyassar',
        'urlTemplate':
            'https://cdn.jsdelivr.net/gh/spa5k/tafsir_api@v1.2.2/tafsir/ar-tafsir-muyassar/{n}.json',
        'fileCount': 114,
        'approxSizeMb': 5.5,
        'version': 'v1.2.2',
      },
      {
        'id': 'ara-sirajtafseer',
        'kind': 'translation',
        'language': 'ar',
        'titleAr': 'المختصر في التفسير (سِراج)',
        'titleEn': 'At-Tafsir Al-Mukhtasar (Siraj)',
        'sourceUrl':
            'https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@1/editions/ara-sirajtafseer.min.json',
        'approxSizeMb': 2.0,
        'version': '1',
      },
      {
        'id': 'ara-bukhari',
        'kind': 'hadith',
        'language': 'ar',
        'titleAr': 'صحيح البخاري',
        'titleEn': 'Sahih al-Bukhari',
        'sourceUrl':
            'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/ara-bukhari.min.json',
        'approxSizeMb': 9.0,
        'version': '1',
      },
    ];

void main() {
  late CatalogRepository repo;

  setUp(() {
    repo = CatalogRepository(
        source: BundledCatalogSource(loader: () async => fixturePacks()));
  });

  test('lists all packs and filters by kind', () async {
    expect(await repo.packs(), hasLength(3));
    final tafsirs = await repo.packs(kind: LibraryPackKind.tafsir);
    expect(tafsirs, hasLength(1));
    expect(tafsirs.single.id, 'ar-tafsir-muyassar');
    expect(tafsirs.single.fileCount, 114);
    expect(tafsirs.single.urlTemplate, isNotNull);
    final hadith = await repo.packs(kind: LibraryPackKind.hadith);
    expect(hadith.single.sourceUrl, isNotNull);
  });

  test('byId resolves known packs and returns null for unknown', () async {
    final pack = await repo.byId('ara-sirajtafseer');
    expect(pack, isNotNull);
    expect(pack!.kind, LibraryPackKind.translation);
    expect(pack.titleAr, isNotEmpty);
    expect(pack.titleEn, isNotEmpty);
    expect(pack.approxSizeMb, greaterThan(0));
    expect(await repo.byId('does-not-exist'), isNull);
  });

  test('malformed entries are rejected, well-formed ones survive', () async {
    final repo2 = CatalogRepository(
      source: BundledCatalogSource(
        loader: () async => [
          {
            'id': 'x1', // missing kind/title/etc.
          },
          {
            'id': 'x2',
            'kind': 'mystery-kind', // unknown kind
            'language': 'ar',
            'titleAr': 'ع',
            'titleEn': 'x',
            'approxSizeMb': 1.0,
            'version': '1',
          },
          {
            'id': 'x3', // tafsir without urlTemplate
            'kind': 'tafsir',
            'language': 'ar',
            'titleAr': 'ع',
            'titleEn': 'x',
            'fileCount': 114,
            'approxSizeMb': 1.0,
            'version': '1',
          },
          ...fixturePacks(),
        ],
      ),
    );
    final packs = await repo2.packs();
    final ids = packs.map((p) => p.id).toSet();
    expect(
        ids, containsAll(<String>['ar-tafsir-muyassar', 'ara-sirajtafseer']));
    expect(packs, hasLength(3));
  });

  test('missing kind is rejected, never crashing the loader', () async {
    final repo2 = CatalogRepository(
      source: BundledCatalogSource(
        loader: () async => [
          {
            'id': 'x-nokind',
            // Every other field present — only `kind` is missing.
            'language': 'ar',
            'titleAr': 'ع',
            'titleEn': 'x',
            'approxSizeMb': 1.0,
            'version': '1',
          },
          ...fixturePacks(),
        ],
      ),
    );
    final packs = await repo2.packs();
    expect(packs.map((p) => p.id), isNot(contains('x-nokind')));
    expect(packs, hasLength(3));
  });

  test('unsafe entries are rejected: bad ids and non-https urls', () async {
    final repo2 = CatalogRepository(
      source: BundledCatalogSource(
        loader: () async => [
          {...fixturePacks()[0], 'id': '../evil'},
          {
            'id': 'http-pack',
            'kind': 'translation',
            'language': 'ar',
            'titleAr': 'ع',
            'titleEn': 'x',
            'sourceUrl': 'http://insecure.example/x.json',
            'approxSizeMb': 1.0,
            'version': '1',
          },
          {
            'id': 'ftp-pack',
            'kind': 'tafsir',
            'language': 'ar',
            'titleAr': 'ع',
            'titleEn': 'x',
            'urlTemplate': 'ftp://insecure.example/{n}.json',
            'fileCount': 114,
            'approxSizeMb': 1.0,
            'version': '1',
          },
          ...fixturePacks(),
        ],
      ),
    );
    final packs = await repo2.packs();
    final ids = packs.map((p) => p.id).toSet();
    expect(ids, isNot(contains('../evil')));
    expect(ids, isNot(contains('http-pack')));
    expect(ids, isNot(contains('ftp-pack')));
    expect(packs, hasLength(3));
  });

  test('bundled library catalog asset is well-formed (9 curated packs)',
      () async {
    final file = File('assets/data/library_catalog.json');
    if (!file.existsSync()) {
      markTestSkipped(
          'working dir does not resolve the bundled asset from this runner');
    }
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final list = (json['packs'] as List).cast<Map<String, dynamic>>();
    expect(list.length, 9);

    final packs = await CatalogRepository(
      source: BundledCatalogSource(loader: () async => list),
    ).packs();
    expect(packs, hasLength(9)); // every entry must parse

    for (final pack in packs) {
      expect(pack.id, isNotEmpty);
      expect(pack.language, isNotEmpty);
      expect(pack.titleAr, isNotEmpty);
      expect(pack.titleEn, isNotEmpty);
      expect(pack.version, isNotEmpty);
      expect(pack.approxSizeMb, greaterThan(0));
      final pinnedUrl = pack.sourceUrl ?? pack.urlTemplate;
      expect(pinnedUrl, startsWith('https://cdn.jsdelivr.net/'),
          reason: 'pack ${pack.id} URL must be pinned to the jsDelivr CDN');
      expect(pinnedUrl, contains('@'),
          reason: 'pack ${pack.id} URL must carry a pinned tag');
      expect(pinnedUrl, isNot(contains('/latest/')),
          reason: 'pack ${pack.id} URL must never float latest');
    }

    final tafsirs = packs.where((p) => p.kind == LibraryPackKind.tafsir);
    expect(tafsirs, hasLength(3));
    for (final pack in tafsirs) {
      expect(pack.urlTemplate, isNotNull);
      expect(pack.urlTemplate!, contains('{n}'),
          reason: 'tafsir template must carry the surah placeholder');
      expect(pack.fileCount, 114);
    }

    final translations =
        packs.where((p) => p.kind == LibraryPackKind.translation);
    expect(translations, hasLength(3));
    final hadiths = packs.where((p) => p.kind == LibraryPackKind.hadith);
    expect(hadiths, hasLength(3));

    final ids = packs.map((p) => p.id).toSet();
    expect(ids.length, 9, reason: 'pack ids must be unique');
    expect(
        ids,
        containsAll(<String>[
          'ar-tafsir-muyassar',
          'ar-tafsir-al-jalalayn',
          'en-tafisr-ibn-kathir',
          'ara-sirajtafseer',
          'eng-safiurrahmanalm',
          'eng-mustafakhattabg',
          'ara-bukhari',
          'eng-bukhari',
          'eng-muslim',
        ]));
  });
}
