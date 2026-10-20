import 'dart:convert';
import 'dart:isolate';

import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;

import '../../../core/db/app_database.dart';
import '../domain/reciter_info.dart';
import 'reciter_info_source.dart';
import 'reciter_mapping.dart';
import 'reciter_source.dart';

/// Featured reciters pinned by PM from the verified 2026-10-15 mp3quran dump
/// (all حفص مرتل, 114 surahs each). Never extend without a PM grant.
const List<int> featuredReciterIds = <int>[
  51,
  123,
  118,
  92,
  102,
  54,
  30,
  4,
  5,
];

/// File name the surah audio is stored under.
String surahAudioFileName(int surahNumber) =>
    '${surahNumber.toString().padLeft(3, '0')}.mp3';

/// Full download URL of a surah audio on [server].
String surahAudioUrl(String server, int surahNumber) {
  final base = server.endsWith('/') ? server : '$server/';
  return '$base${surahAudioFileName(surahNumber)}';
}

/// Parses the comma-separated surah list of a moshaf.
List<int> parseSurahList(String csv) => csv
    .split(',')
    .map((part) => int.tryParse(part.trim()))
    .whereType<int>()
    .toList();

/// Sorts reciters by featured order, then by name.
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

/// True when the row belongs to a featured reciter.
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

/// Keeps the reciter catalog in sync with the remote API and the local database.
class ReciterRepository implements ReciterSource, ReciterInfoSource {
  ReciterRepository(
    this._db, {
    http.Client? client,
    String? apiEndpointOverride,
  })  : _client = client ?? http.Client(),
        _endpoint = apiEndpointOverride ?? recitersApiEndpoint;

  final AppDatabase _db;
  final http.Client _client;
  final String _endpoint;

  /// Parses the catalog payload on a worker isolate.
  ///
  /// It is STATIC on purpose: a closure created inside an instance method
  /// captures the receiver - and this repository holds the http client,
  /// which is not sendable to another isolate.
  static Future<Object?> _decodePayloadOnWorker(String body) =>
      Isolate.run<Object?>(() => jsonDecode(body));

  /// Refreshes the reciter catalog from the mp3quran API.
  ///
  /// The payload is deliberately NOT hash-pinned: upstream mutates the
  /// catalog (reciters and moshafs are added over time), so a full-payload
  /// sha256 pin would break the app on every upstream edit. What protects
  /// the app instead: (1) every `server` that survives parsing passes the
  /// [isTrustedAudioServer] allowlist before a row is written, and (2) the
  /// payload must clear the sanity floor below - a tampered or truncated
  /// response is rejected (the caller surfaces the localized error) instead
  /// of replacing the cached list with an empty one.
  @override
  Future<void> refreshFromApi() async {
    final res = await _client
        .get(Uri.parse(_endpoint))
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw StateError('mp3quran HTTP ${res.statusCode}');
    }
    final body = res.body;
    // The payload holds hundreds of reciters: the JSON decode runs on a
    // worker isolate so the UI isolate never parses it. Everything that
    // follows - the host allowlist and the sanity floor - still runs here,
    // on the PARSED rows.
    final data = await _decodePayloadOnWorker(body);
    if (data is! Map<String, dynamic>) {
      throw StateError('mp3quran payload is not a JSON object');
    }
    final reciters = data['reciters'];
    if (reciters is! List) {
      throw StateError('mp3quran payload is missing the reciters list');
    }
    final rows = <RecitersCompanion>[];
    var featuredPresent = false;
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
        // The allowlist is the only gate a `server` passes: a foreign host
        // is rejected here, so it is never stored and never streamed.
        if (server is! String || !isTrustedAudioServer(server)) continue;
        final moshafName = moshaf['name'];
        final surahList = moshaf['surah_list'];
        final surahTotal = moshaf['surah_total'];
        final reciterIdInt = reciterId.toInt();
        if (featuredReciterIds.contains(reciterIdInt)) featuredPresent = true;
        rows.add(RecitersCompanion.insert(
          id: '$reciterIdInt-${moshafId.toInt()}',
          reciterName: reciterName is String ? reciterName : '',
          moshafName: moshafName is String ? moshafName : '',
          server: server,
          surahList: surahList is String ? surahList : '',
          surahTotal: surahTotal is num ? surahTotal.toInt() : 0,
        ));
      }
    }
    // Sanity floor: the payload must yield at least one trusted row and
    // keep a pinned featured reciter, otherwise a tampered or truncated
    // response would leave the app with an empty reciter list.
    if (rows.isEmpty || !featuredPresent) {
      throw StateError(
          'mp3quran payload failed the sanity floor: ${rows.length} trusted rows, featured=$featuredPresent');
    }
    await _db.transaction(() async {
      await _db.delete(_db.reciters).go();
      await _db.batch((b) => b.insertAll(_db.reciters, rows));
    });
  }

  @override
  Stream<List<ReciterRow>> watchAll() => _db.select(_db.reciters).watch();

  /// The selected reciter, or the first featured one when nothing is picked.
  /// The repository is the mapping boundary: rows become entities here.
  @override
  Future<ReciterInfo?> defaultReciter() async {
    final selectedId = await loadSelectedMoshaf();
    if (selectedId != null) {
      final selected = await byId(selectedId);
      if (selected != null) return selected.toInfo();
    }
    final all = sortReciters(await watchAll().first);
    if (all.isEmpty) return null;
    return all.first.toInfo();
  }

  @override
  Future<ReciterRow?> byId(String rowId) =>
      (_db.select(_db.reciters)..where((r) => r.id.equals(rowId)))
          .getSingleOrNull();

  @override
  Future<void> selectMoshaf(String rowId) async {
    await _db.into(_db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: selectedMoshafKey,
            value: rowId,
          ),
        );
  }

  @override
  Future<String?> loadSelectedMoshaf() async {
    final row = await (_db.select(_db.settingsTable)
          ..where((s) => s.key.equals(selectedMoshafKey)))
        .getSingleOrNull();
    return row?.value;
  }

  @override
  Future<Map<int, String>> surahNamesFor(List<int> surahIds) async {
    if (surahIds.isEmpty) return {};
    final rows =
        await (_db.select(_db.surahs)..where((s) => s.id.isIn(surahIds))).get();
    return {for (final s in rows) s.id: s.nameAr};
  }

  /// Opening-ayah teasers for the reciter's surah rows (W2a plan T6 shape),
  /// keyed by surah id from the bundled ayahs table.
  @override
  Future<Map<int, String>> ayahTeasersFor(List<int> surahIds) async {
    if (surahIds.isEmpty) return {};
    final rows = await (_db.select(_db.ayahs)
          ..where((a) => a.surahId.isIn(surahIds) & a.numberInSurah.equals(1)))
        .get();
    return {for (final a in rows) a.surahId: a.textUthmani};
  }
}
