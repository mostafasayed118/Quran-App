import '../../../core/utils/cached_loader.dart';

/// One of the ninety-nine names with its Arabic/English name and meaning.
class AsmaName {
  const AsmaName({
    required this.n,
    required this.nameAr,
    required this.nameEn,
    required this.meaningAr,
    required this.meaningEn,
  });

  /// The name's number, 1..99.
  final int n;

  /// Arabic spelling of the name.
  final String nameAr;

  /// English transliteration of the name.
  final String nameEn;

  /// Arabic meaning of the name.
  final String meaningAr;

  /// English meaning of the name.
  final String meaningEn;

  factory AsmaName.fromJson(Map<String, dynamic> json) => AsmaName(
        n: (json['n'] as num).toInt(),
        nameAr: json['nameAr'] as String,
        nameEn: json['nameEn'] as String,
        meaningAr: json['meaningAr'] as String,
        meaningEn: json['meaningEn'] as String,
      );
}

/// Reads the bundled ninety-nine-names catalog.
class AsmaRepository {
  AsmaRepository({
    required Future<List<Map<String, dynamic>>> Function() loader,
  }) : _loader = loader;

  final Future<List<Map<String, dynamic>>> Function() _loader;

  late final CachedLoader<List<AsmaName>> _names = CachedLoader(_load);

  /// All names in order; the catalog is loaded once and cached.
  Future<List<AsmaName>> names() {
    return _names.load();
  }

  Future<List<AsmaName>> _load() async {
    final raw = await _loader();
    return [for (final row in raw) AsmaName.fromJson(row)]
      ..sort((a, b) => a.n.compareTo(b.n));
  }
}
