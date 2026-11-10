/// One supplication with its category and repetition count.
class DuaEntry {
  const DuaEntry({
    required this.id,
    required this.categoryAr,
    required this.text,
    this.reference,
    this.count = 1,
  });

  /// Stable id of the dua.
  final String id;

  /// Arabic category name the dua belongs to.
  final String categoryAr;

  /// Arabic text of the dua.
  final String text;

  /// Optional source reference for the dua.
  final String? reference;

  /// How many times it should be recited.
  final int count;

  factory DuaEntry.fromJson(Map<String, dynamic> json) => DuaEntry(
        id: json['id'] as String,
        categoryAr: json['categoryAr'] as String,
        text: json['text'] as String,
        reference: json['reference'] as String?,
        count: (json['count'] as int?) ?? 1,
      );
}
