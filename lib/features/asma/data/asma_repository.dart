class AsmaName {
  const AsmaName({
    required this.n,
    required this.nameAr,
    required this.nameEn,
    required this.meaningAr,
    required this.meaningEn,
  });

  final int n;
  final String nameAr;
  final String nameEn;
  final String meaningAr;
  final String meaningEn;

  factory AsmaName.fromJson(Map<String, dynamic> json) => AsmaName(
        n: (json['n'] as num).toInt(),
        nameAr: json['nameAr'] as String,
        nameEn: json['nameEn'] as String,
        meaningAr: json['meaningAr'] as String,
        meaningEn: json['meaningEn'] as String,
      );
}

class AsmaRepository {
  AsmaRepository({
    required Future<List<Map<String, dynamic>>> Function() loader,
  }) : _loader = loader;

  final Future<List<Map<String, dynamic>>> Function() _loader;

  List<AsmaName>? _cache;

  Future<List<AsmaName>> names() async {
    final cached = _cache;
    if (cached != null) return cached;
    final raw = await _loader();
    final names = [for (final row in raw) AsmaName.fromJson(row)]
      ..sort((a, b) => a.n.compareTo(b.n));
    _cache = names;
    return names;
  }
}
