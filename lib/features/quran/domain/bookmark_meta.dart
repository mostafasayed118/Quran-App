/// One bookmark's user metadata: an optional folder name and a note.
class BookmarkMetaEntry {
  /// Creates an entry; both fields are trimmed by [normalized].
  const BookmarkMetaEntry({this.folder = '', this.note = ''});

  /// The free-text folder name; empty means "no folder".
  final String folder;

  /// The user's note; empty means "no note".
  final String note;

  /// Whether both fields are empty (the entry should not be stored).
  bool get isEmpty => folder.isEmpty && note.isEmpty;

  /// A trimmed copy; empty fields are stored as empty strings.
  BookmarkMetaEntry normalized() =>
      BookmarkMetaEntry(folder: folder.trim(), note: note.trim());

  /// A copy with the given fields replaced.
  BookmarkMetaEntry copyWith({String? folder, String? note}) =>
      BookmarkMetaEntry(
        folder: folder ?? this.folder,
        note: note ?? this.note,
      );

  /// The persisted shape.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'folder': folder,
        'note': note,
      };

  /// Decodes a persisted entry; missing fields degrade to empty.
  factory BookmarkMetaEntry.fromJson(Map<String, dynamic> json) =>
      BookmarkMetaEntry(
        folder: (json['folder'] as String? ?? '').trim(),
        note: (json['note'] as String? ?? '').trim(),
      );

  @override
  bool operator ==(Object other) =>
      other is BookmarkMetaEntry &&
      other.folder == folder &&
      other.note == note;

  @override
  int get hashCode => Object.hash(folder, note);
}
