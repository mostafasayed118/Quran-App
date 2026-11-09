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
