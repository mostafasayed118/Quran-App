import '../../../core/utils/cached_loader.dart';

class RuqyahEntry {
  const RuqyahEntry({
    required this.id,
    required this.kind,
    this.surahId,
    this.fromAyah,
    this.toAyah,
    this.text,
    this.count = 1,
    this.reference,
  });

  final String id;

  /// 'quran' (range reference — text resolved from the bundled DB) or 'dhikr'.
  final String kind;
  final int? surahId;
  final int? fromAyah;
  final int? toAyah;
  final String? text;
  final int count;
  final String? reference;

  bool get isQuran => kind == 'quran';

  factory RuqyahEntry.fromJson(Map<String, dynamic> json) => RuqyahEntry(
        id: json['id'] as String,
        kind: json['kind'] as String,
        surahId: (json['surahId'] as num?)?.toInt(),
        fromAyah: (json['fromAyah'] as num?)?.toInt(),
        toAyah: (json['toAyah'] as num?)?.toInt(),
        text: json['text'] as String?,
        count: (json['count'] as int?) ?? 1,
        reference: json['reference'] as String?,
      );
}

class RuqyahRepository {
  RuqyahRepository({
    required Future<List<Map<String, dynamic>>> Function() loader,
  }) : _loader = loader;

  final Future<List<Map<String, dynamic>>> Function() _loader;

  late final CachedLoader<List<RuqyahEntry>> _entries = CachedLoader(_load);

  Future<List<RuqyahEntry>> entries() {
    return _entries.load();
  }

  Future<List<RuqyahEntry>> _load() async {
    final raw = await _loader();
    return [for (final row in raw) RuqyahEntry.fromJson(row)];
  }
}
