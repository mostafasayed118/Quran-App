class AzkarItem {
  const AzkarItem({
    required this.text,
    this.count = 1,
    this.virtue,
    this.reference,
  });

  final String text;
  final int count;
  final String? virtue;
  final String? reference;

  factory AzkarItem.fromJson(Map<String, dynamic> json) => AzkarItem(
        text: json['text'] as String,
        count: (json['count'] as int?) ?? 1,
        virtue: json['virtue'] as String?,
        reference: json['reference'] as String?,
      );
}

class AzkarCollection {
  const AzkarCollection({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.items,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final List<AzkarItem> items;

  factory AzkarCollection.fromJson(Map<String, dynamic> json) =>
      AzkarCollection(
        id: json['id'] as String,
        nameAr: json['nameAr'] as String,
        nameEn: json['nameEn'] as String,
        items: [
          for (final item
              in (json['items'] as List).cast<Map<String, dynamic>>())
            AzkarItem.fromJson(item),
        ],
      );
}

class AzkarRepository {
  AzkarRepository({required Future<Map<String, dynamic>> Function() loader})
      : _loader = loader;

  final Future<Map<String, dynamic>> Function() _loader;

  Future<List<AzkarCollection>>? _cache;

  Future<List<AzkarCollection>> collections() {
    return _cache ??= _load().catchError((Object error, StackTrace stackTrace) {
      _cache = null;
      throw error;
    });
  }

  Future<List<AzkarCollection>> _load() async {
    final root = await _loader();
    final raw = (root['collections'] as List).cast<Map<String, dynamic>>();
    return [for (final collection in raw) AzkarCollection.fromJson(collection)];
  }
}
