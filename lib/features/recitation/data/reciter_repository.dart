import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;

import '../../../core/db/app_database.dart';

/// Featured reciters pinned by PM from the verified 2026-10-15 mp3quran dump
/// (all حفص مرتل, 114 surahs each). Never extend without a PM grant.
const List<int> featuredReciterIds = <int>[
  51, 123, 118, 92, 102, 54, 30, 4, 5,
];

String surahAudioFileName(int surahNumber) =>
    '${surahNumber.toString().padLeft(3, '0')}.mp3';

String surahAudioUrl(String server, int surahNumber) {
  final base =
      server.endsWith('/') ? server : '$server/';
  return '$base${surahAudioFileName(surahNumber)}';
}

List<int> parseSurahList(String csv) => csv
    .split(',')
    .map((part) => int.tryParse(part.trim()))
    .whereType<int>()
    .toList();

List<ReciterRow> sortReciters(List<ReciterRow> input) {
  var featuredRank = 0;
  final ranks = <int, int>{};
  for (final id in featuredReciterIds) {
    ranks[id] = featuredRank;
    featuredRank += 1;
  }
  int rankOf(ReciterRow row) {
    final leadingId = int.tryParse(row.id.split('-').first);
    final featured = leadingId == null ? null : ranks[leadingId];
    return featured ?? featuredReciterIds.length;
  }

  // Ranks are computed once per row: the comparator runs O(n log n) times,
  // and splitting ids inside it is pure waste.
  final ranksById = {for (final row in input) row.id: rankOf(row)};
  final sorted = [...input]..sort((a, b) {
      final byFeature = ranksById[a.id]!.compareTo(ranksById[b.id]!);
      if (byFeature != 0) return byFeature;
      final byName = a.reciterName.compareTo(b.reciterName);
      if (byName != 0) return byName;
      return a.id.compareTo(b.id);
    });
  return sorted;
}

bool isFeaturedReciterRow(ReciterRow row) {
  final leadingId = int.tryParse(row.id.split('-').first);
  return leadingId != null && featuredReciterIds.contains(leadingId);
}

/// The mp3quran API is the only writer of `server` values and its audio
/// hosts live on mp3quran.net; anything else (http, foreign host, malformed)
/// is dropped at parse time so it can never be streamed or downloaded.
bool isTrustedAudioServer(String server) {
  final uri = Uri.tryParse(server);
  return uri != null &&
      uri.scheme == 'https' &&
      uri.host.isNotEmpty &&
      (uri.host == 'mp3quran.net' || uri.host.endsWith('.mp3quran.net'));
}

const recitersApiEndpoint = 'https://mp3quran.net/api/v3/reciters?language=ar';
const selectedMoshafKey = 'selected_moshaf_row';

class ReciterRepository {
  ReciterRepository(
    this._db, {
    http.Client? client,
    String? apiEndpointOverride,
  })  : _client = client ?? http.Client(),
        _endpoint = apiEndpointOverride ?? recitersApiEndpoint;

  final AppDatabase _db;
  final http.Client _client;
  final String _endpoint;

  Future<void> refreshFromApi() async {
    final res = await _client
        .get(Uri.parse(_endpoint))
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw StateError('mp3quran HTTP ${res.statusCode}');
    }
    final data = jsonDecode(res.body);
    if (data is! Map<String, dynamic>) {
      throw StateError('mp3quran payload is not a JSON object');
    }
    final reciters = data['reciters'];
    if (reciters is! List) {
      throw StateError('mp3quran payload is missing the reciters list');
    }
    final rows = <RecitersCompanion>[];
    for (final reciter in reciters) {
      if (reciter is! Map<String, dynamic>) continue;
      final reciterId = reciter['id'];
      if (reciterId is! num) continue;
      final reciterName = reciter['name'];
      final moshafs = reciter['moshaf'];
      if (moshafs is! List) continue;
      for (final moshaf in moshafs) {
        if (moshaf is! Map<String, dynamic>) continue;
        final moshafId = moshaf['id'];
        if (moshafId is! num) continue;
        final server = moshaf['server'];
        if (server is! String || !isTrustedAudioServer(server)) continue;
        final moshafName = moshaf['name'];
        final surahList = moshaf['surah_list'];
        final surahTotal = moshaf['surah_total'];
        rows.add(RecitersCompanion.insert(
          id: '${reciterId.toInt()}-${moshafId.toInt()}',
          reciterName: reciterName is String ? reciterName : '',
          moshafName: moshafName is String ? moshafName : '',
          server: server,
          surahList: surahList is String ? surahList : '',
          surahTotal: surahTotal is num ? surahTotal.toInt() : 0,
        ));
      }
    }
    await _db.transaction(() async {
      await _db.delete(_db.reciters).go();
      await _db.batch((b) => b.insertAll(_db.reciters, rows));
    });
  }

  Stream<List<ReciterRow>> watchAll() => _db.select(_db.reciters).watch();

  Future<ReciterRow?> byId(String rowId) =>
      (_db.select(_db.reciters)..where((r) => r.id.equals(rowId)))
          .getSingleOrNull();

  Future<void> selectMoshaf(String rowId) async {
    await _db.into(_db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: selectedMoshafKey,
            value: rowId,
          ),
        );
  }

  Future<String?> loadSelectedMoshaf() async {
    final row = await (_db.select(_db.settingsTable)
          ..where((s) => s.key.equals(selectedMoshafKey)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<Map<int, String>> surahNamesFor(List<int> surahIds) async {
    if (surahIds.isEmpty) return {};
    final rows = await (_db.select(_db.surahs)
          ..where((s) => s.id.isIn(surahIds)))
        .get();
    return {for (final s in rows) s.id: s.nameAr};
  }

  /// Opening-ayah teasers for the reciter's surah rows (W2a plan T6 shape),
  /// keyed by surah id from the bundled ayahs table.
  Future<Map<int, String>> ayahTeasersFor(List<int> surahIds) async {
    if (surahIds.isEmpty) return {};
    final rows = await (_db.select(_db.ayahs)
          ..where((a) => a.surahId.isIn(surahIds) & a.numberInSurah.equals(1)))
        .get();
    return {for (final a in rows) a.surahId: a.textUthmani};
  }
}
