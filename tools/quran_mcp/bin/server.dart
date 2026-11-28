// Experimental MCP server over the Quran Yahdi offline assets.
//
// Run from the app root:
//   dart run tools/quran_mcp/bin/server.dart
//
// Or point it at the app explicitly:
//   dart run tools/quran_mcp/bin/server.dart --root D:\path\to\quran-app
import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:dart_mcp/server.dart';
import 'package:dart_mcp/stdio.dart';
import 'package:sqlite3/sqlite3.dart';

void main(List<String> args) {
  // Resolved against the process cwd, so `--root ..\..` works no matter how
  // the client spelled it, and error messages carry a usable path.
  final root = io.Directory(
    _argValue(args, '--root') ?? io.Directory.current.path,
  ).absolute.path;
  QuranMcpServer(stdioChannel(input: io.stdin, output: io.stdout), root);
}

String? _argValue(List<String> args, String name) {
  final index = args.indexOf(name);
  if (index == -1 || index + 1 >= args.length) return null;
  return args[index + 1];
}

base class QuranMcpServer extends MCPServer with ToolsSupport {
  QuranMcpServer(super.channel, this.root)
    : super.fromStreamChannel(
        implementation: Implementation(
          name: 'quran-yahdi-assets',
          version: '0.2.0',
        ),
        instructions:
            'Read-only tools over the Quran Yahdi offline content. '
            'Use quran_search to find ayahs by Arabic text and quran_surah to '
            "inspect a surah. Search the imla'i spelling that quran_surah "
            'returns; the Uthmani script spells some words differently.',
      ) {
    registerTool(searchTool, _search);
    registerTool(surahTool, _surah);
  }

  /// Absolute path to the Quran Yahdi checkout.
  final String root;

  /// Lazily opened, read-only handle to the shipped content database.
  Database? _databaseHandle;

  /// The shortest token the FTS5 `trigram` tokenizer can represent.
  ///
  /// A shorter token matches nothing through `MATCH` and is dropped from the
  /// expression, so such queries fall back to the substring scan instead.
  static const int _ftsTrigramMinTokenLength = 3;

  /// Mirrors `kQuranSearchMaxTokens` in the app: a longer query is a paste
  /// artefact, and the substring path binds one SQL variable per token.
  static const int _maxTokens = 64;

  /// Mirrors `kQuranSearchMinChars` in the app: a one-letter query matches
  /// thousands of ayahs and is noise, not a search.
  static const int _minQueryChars = 2;

  final searchTool = Tool(
    name: 'quran_search',
    description:
        'Search the offline Quran text shipped with this app. Reads the '
        "readable imla'i text from assets/db/quran.sqlite and normalizes "
        'Arabic the same way the app does: diacritics are ignored and letter '
        'variants are folded, so "الصلاة" matches "الصلاه". The Uthmani '
        'script spells some words differently (e.g. "الصلوة"); quran_surah '
        "returns the imla'i form of every ayah for searching.",
    inputSchema: Schema.object(
      properties: {
        'query': Schema.string(
          description: 'Arabic text to search for, e.g. الصلاة',
        ),
        'surah': Schema.int(
          description: 'Optional surah number (1-114) to limit the search',
        ),
        'limit': Schema.int(
          description: 'Maximum number of results (default 10, max 50)',
        ),
        'offset': Schema.int(
          description: 'Skip this many matches before returning results',
        ),
      },
      required: ['query'],
    ),
  );

  final surahTool = Tool(
    name: 'quran_surah',
    description:
        'Return the surah name, ayah count, and ayahs from the offline '
        "Uthmani text, with the imla'i text included for searching.",
    inputSchema: Schema.object(
      properties: {
        'surah': Schema.int(description: 'Surah number (1-114)'),
        'limit': Schema.int(
          description: 'How many ayahs to return (default 5, max 20)',
        ),
      },
      required: ['surah'],
    ),
  );

  FutureOr<CallToolResult> _search(CallToolRequest request) async {
    final query = (request.arguments?['query'] as String?)?.trim();
    if (query == null || query.isEmpty) {
      return _error('query is required');
    }
    final tokens = _searchTokens(query);
    if (tokens.isEmpty) {
      return _error('query has no searchable Arabic characters');
    }
    if (tokens.join().length < _minQueryChars) {
      return _error(
        'query must contain at least $_minQueryChars Arabic characters',
      );
    }
    final surahFilter = request.arguments?['surah'] as int?;
    if (surahFilter != null && (surahFilter < 1 || surahFilter > 114)) {
      // Without this, an out-of-range filter silently reads as "no such ayah".
      return _error('surah must be between 1 and 114');
    }
    final limit = ((request.arguments?['limit'] as int?) ?? 10).clamp(1, 50);
    final requestedOffset = (request.arguments?['offset'] as int?) ?? 0;
    final offset = requestedOffset < 0 ? 0 : requestedOffset;

    final Database db;
    try {
      db = _database();
    } on Object catch (error) {
      return _error(
        'cannot open $root/assets/db/quran.sqlite read-only: $error',
      );
    }
    if (!_hasSearchIndex(db)) {
      return _error(
        'the content database has no ayah_search index; it predates this '
        'tool. Rebuild it with the app (lib/core/db/search_index.dart).',
      );
    }

    // Every token must appear (AND), matching the app's search semantics. A
    // token shorter than a trigram cannot be expressed through MATCH, so the
    // whole query falls back to the substring scan over the same index.
    final useFts = tokens.every((t) => t.length >= _ftsTrigramMinTokenLength);
    final where = StringBuffer();
    final variables = <Object?>[];
    if (useFts) {
      where.write('ayah_search MATCH ?');
      variables.add(
        tokens.map((t) => '"${t.replaceAll('"', '""')}"').join(' '),
      );
    } else {
      for (var i = 0; i < tokens.length; i++) {
        if (i > 0) where.write(' AND ');
        where.write('ayah_search.text_norm LIKE ?');
        variables.add('%${tokens[i]}%');
      }
    }
    if (surahFilter != null) {
      where.write(' AND a.surah_id = ?');
      variables.add(surahFilter);
    }

    final ResultSet rows;
    final int total;
    try {
      // The page is capped, the total is not: a caller that only sees the
      // page length cannot tell "2 matches" from "2 shown".
      total =
          db
                  .select(
                    'SELECT count(*) AS c FROM ayah_search '
                    'JOIN ayahs a ON a.id = ayah_search.rowid '
                    'WHERE $where',
                    variables,
                  )
                  .first['c']
              as int;
      rows = db.select(
        'SELECT ayah_search.rowid AS ayah_id, a.surah_id, '
        'a.number_in_surah, u.name_ar, a.text_imlaei '
        'FROM ayah_search '
        'JOIN ayahs a ON a.id = ayah_search.rowid '
        'JOIN surahs u ON u.id = a.surah_id '
        'WHERE $where '
        'ORDER BY ayah_search.rowid LIMIT ? OFFSET ?',
        [...variables, limit, offset],
      );
    } on Object catch (error) {
      return _error('search failed: $error');
    }

    return _json({
      'query': query,
      'tokens': tokens,
      'strategy': useFts ? 'fts5-trigram' : 'substring',
      'script': 'imlaei',
      'source': 'assets/db/quran.sqlite',
      'total': total,
      'offset': offset,
      'returned': rows.length,
      'has_more': offset + rows.length < total,
      'results': [
        for (final row in rows)
          {
            'surah': row['surah_id'],
            'surah_name': row['name_ar'],
            'ayah': row['number_in_surah'],
            'text': row['text_imlaei'],
          },
      ],
    });
  }

  FutureOr<CallToolResult> _surah(CallToolRequest request) async {
    final surah = request.arguments?['surah'] as int?;
    if (surah == null || surah < 1 || surah > 114) {
      return _error('surah must be between 1 and 114');
    }
    final limit = ((request.arguments?['limit'] as int?) ?? 5).clamp(1, 20);
    final Map<String, String>? ayahs;
    try {
      ayahs = await _readSurah(surah);
    } on FormatException catch (error) {
      return _error(
        'assets/quran/uthmani/$surah.json is corrupt: ${error.message}',
      );
    } on Object catch (error) {
      return _error('cannot read assets/quran/uthmani/$surah.json: $error');
    }
    if (ayahs == null) {
      return _error(
        'assets/quran/uthmani/$surah.json was not found under $root',
      );
    }
    final entries = ayahs.entries.toList()
      ..sort(
        (a, b) =>
            (int.tryParse(a.key) ?? 0).compareTo(int.tryParse(b.key) ?? 0),
      );
    final enrichment = _surahEnrichment(surah);
    return _json({
      'surah': surah,
      'surah_name': enrichment.name,
      'script': 'uthmani',
      'ayah_count': entries.length,
      'ayahs': [
        for (final entry in entries.take(limit))
          {
            'ayah': int.tryParse(entry.key),
            'text': entry.value,
            'text_imlaei': enrichment.imlaei[int.tryParse(entry.key) ?? 0],
          },
      ],
    });
  }

  Database _database() => _databaseHandle ??= _openDatabase();

  Database _openDatabase() {
    final db = sqlite3.open(
      '$root/assets/db/quran.sqlite',
      mode: OpenMode.readOnly,
    );
    final tables = db
        .select("SELECT name FROM sqlite_master WHERE type = 'table'")
        .map((row) => row['name'] as String)
        .toSet();
    final missing = const {'ayahs', 'surahs'}.difference(tables);
    if (missing.isNotEmpty) {
      db.close();
      throw StateError(
        'content database is missing ${missing.join(', ')}; '
        'it is not a Quran Yahdi content database',
      );
    }
    return db;
  }

  /// The FTS index is rebuilt by the app; an older content DB can lack it.
  bool _hasSearchIndex(Database db) => db
      .select(
        "SELECT 1 FROM sqlite_master WHERE type = 'table' "
        "AND name = 'ayah_search'",
      )
      .isNotEmpty;

  /// Surah name and imla'i text for the ayahs, when the database is readable.
  ///
  /// Enrichment only: the Uthmani JSON is the tool's contract, so a missing or
  /// stale database must not fail `quran_surah`.
  ({String? name, Map<int, String> imlaei}) _surahEnrichment(int surah) {
    try {
      final db = _database();
      final name = db.select('SELECT name_ar FROM surahs WHERE id = ?', [
        surah,
      ]);
      final rows = db.select(
        'SELECT number_in_surah, text_imlaei FROM ayahs WHERE surah_id = ?',
        [surah],
      );
      return (
        name: name.isEmpty ? null : name.first['name_ar'] as String?,
        imlaei: {
          for (final row in rows)
            row['number_in_surah'] as int: row['text_imlaei'] as String,
        },
      );
    } on Object {
      return (name: null, imlaei: const <int, String>{});
    }
  }

  Future<Map<String, String>?> _readSurah(int surah) async {
    final file = io.File('$root/assets/quran/uthmani/$surah.json');
    if (!await file.exists()) return null;
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map) {
      throw const FormatException(
        'expected a JSON object of ayah number -> text',
      );
    }
    return decoded.map(
      (key, value) => MapEntry(key.toString(), value.toString()),
    );
  }

  CallToolResult _json(Object value) => CallToolResult(
    content: [
      TextContent(text: const JsonEncoder.withIndent('  ').convert(value)),
    ],
  );

  CallToolResult _error(String message) =>
      CallToolResult(isError: true, content: [TextContent(text: message)]);
}

/// Splits a raw query into normalized search tokens, capped at [_maxTokens].
///
/// Mirrors `quranSearchTokens` in the app: normalize, lowercase, drop
/// punctuation, then split on whitespace.
List<String> _searchTokens(String query) {
  final normalized = _normalize(query).toLowerCase();
  final words = normalized.replaceAll(_nonSearchChars, ' ').trim();
  if (words.isEmpty) return const [];
  final tokens = <String>[];
  for (final token in words.split(RegExp(r'\s+'))) {
    if (tokens.length >= QuranMcpServer._maxTokens) break;
    tokens.add(token);
  }
  return tokens;
}

/// Mirrors `normalizeArabic` in `lib/core/utils/arabic_search.dart`: strips
/// diacritics, the superscript alef and tatweel, then folds letter variants.
String _normalize(String input) {
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    if (_isArabicMark(rune)) continue;
    buffer.writeCharCode(_foldArabicLetter(rune));
  }
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

bool _isArabicMark(int rune) =>
    (rune >= 0x064B && rune <= 0x065F) || rune == 0x0670 || rune == 0x0640;

int _foldArabicLetter(int rune) => switch (rune) {
  0x0622 || 0x0623 || 0x0625 || 0x0671 => 0x0627, // آ أ إ ٱ -> ا
  0x0624 => 0x0648, // ؤ -> و
  0x0626 || 0x0649 => 0x064A, // ئ ى -> ي
  0x0629 => 0x0647, // ة -> ه
  _ => rune,
};

final RegExp _nonSearchChars = RegExp(r'[^\u0621-\u064A\u0660-\u0669a-z0-9]+');
