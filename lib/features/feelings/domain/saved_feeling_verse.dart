import 'feeling.dart';

/// A saved verse row as shown in Q46.
class SavedFeelingVerse {
  const SavedFeelingVerse({
    required this.id,
    required this.ayahId,
    required this.feeling,
    required this.createdAt,
  });

  final int id;
  final int ayahId;
  final FeelingKey feeling;
  final DateTime createdAt;
}
