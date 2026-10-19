/// Pure khatma progress math (no DB, no Flutter): the active plan's
/// read-up-to pointer and chosen pace, turned into everything the wird card
/// shows.
class KhatmaProgress {
  const KhatmaProgress({
    required this.pointerAyahId,
    required this.pointerPage,
    required this.targetPages,
    required this.readerSurahId,
    required this.readerAyahNumber,
  });

  /// Full mushaf page count (Madani layout, pages 1..604).
  static const int totalPages = 604;

  /// The four offered paces, stored as the monthly mushaf portion in pages:
  /// 604 = a khatma every month, 302 = every 2 months, 201 = every 3,
  /// 151 = every 4.
  static const List<int> targetChoices = [604, 302, 201, 151];

  static int dailyPagesFor(int targetPages) =>
      (targetPages / 30).round().clamp(1, totalPages);

  /// Read-up-to pointer: global ayah id (1..6236).
  final int pointerAyahId;

  /// Mushaf page (1..604) holding [pointerAyahId].
  final int pointerPage;

  final int targetPages;

  /// Reader-route coordinates of the pointer (for the open-wird CTA).
  final int readerSurahId;
  final int readerAyahNumber;

  int get dailyPages => dailyPagesFor(targetPages);

  /// The khatma is complete once the pointer reaches the last page.
  bool get completed => pointerPage >= totalPages;

  int get pagesDone => (pointerPage - 1).clamp(0, totalPages);
  double get fraction => pagesDone / totalPages;

  int get todayStartPage => pointerPage.clamp(1, totalPages);
  int get todayEndPage => (pointerPage + dailyPages - 1).clamp(1, totalPages);

  int get remainingPages => totalPages - pagesDone;
  int get remainingDays => (remainingPages / dailyPages).ceil();
}
