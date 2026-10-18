import '../../../core/utils/cached_loader.dart';

class DuaEntry {
  const DuaEntry({
    required this.id,
    required this.categoryAr,
    required this.categoryEn,
    required this.text,
    this.reference,
    this.count = 1,
  });

  final String id;
  final String categoryAr;
  final String categoryEn;
  final String text;
  final String? reference;
  final int count;

  factory DuaEntry.fromJson(Map<String, dynamic> json) => DuaEntry(
        id: json['id'] as String,
        categoryAr: json['categoryAr'] as String,
        categoryEn: json['categoryEn'] as String,
        text: json['text'] as String,
        reference: json['reference'] as String?,
        count: (json['count'] as int?) ?? 1,
      );
}

class DuaRepository {
  DuaRepository({
    required Future<List<Map<String, dynamic>>> Function() loader,
  }) : _loader = loader;

  final Future<List<Map<String, dynamic>>> Function() _loader;

  late final CachedLoader<List<DuaEntry>> _entries = CachedLoader(_load);

  Future<List<DuaEntry>> entries() {
    return _entries.load();
  }

  Future<List<DuaEntry>> _load() async {
    final raw = await _loader();
    return [for (final row in raw) DuaEntry.fromJson(row)];
  }

  Future<List<DuaEntry>> byCategory(String categoryAr) async {
    final all = await entries();
    return [
      for (final entry in all)
        if (entry.categoryAr == categoryAr) entry,
    ];
  }

  Future<List<String>> categories() async {
    final all = await entries();
    final seen = <String>{};
    return [
      for (final entry in all)
        if (seen.add(entry.categoryAr)) entry.categoryAr,
    ];
  }
}
