/// Pure khatma progress math (no DB, no Flutter): the active plan's
/// read-up-to pointer and chosen pace, turned into everything the wird card
/// shows.
class KhatmaProgress {
  /// The reading-plan state shown by the tracker.
  const KhatmaProgress({
    required this.pointerAyahId,
    required this.pointerPage,
    required this.targetPages,
    required this.readerSurahId,
    required this.readerAyahNumber,
  });

  /// Full mushaf page count (Madani layout, pages 1..604).
  static const int totalPages = 604;

  /// Monthly mushaf portion: one khatma per month.
  static const int pagesPerMonth = 604;

  /// Monthly mushaf portion: one khatma every two months.
  static const int pagesPerTwoMonths = 302;

  /// Monthly mushaf portion: one khatma every three months.
  static const int pagesPerThreeMonths = 201;

  /// Monthly mushaf portion: one khatma every four months.
  static const int pagesPerFourMonths = 151;

  /// Days a khatma plan is spread over.
  static const int daysPerKhatmaMonth = 30;

  /// First page of the mushaf.
  static const int firstMushafPage = 1;

  /// The four offered paces, stored as the monthly mushaf portion in pages.
  static const List<int> targetChoices = [
    pagesPerMonth,
    pagesPerTwoMonths,
    pagesPerThreeMonths,
    pagesPerFourMonths,
  ];

  /// Pages to read per day for a plan of [targetPages].
  static int dailyPagesFor(int targetPages) =>
      (targetPages / daysPerKhatmaMonth)
          .round()
          .clamp(firstMushafPage, totalPages);

  /// Read-up-to pointer: global ayah id (1..6236).
  final int pointerAyahId;

  /// Mushaf page (1..604) holding [pointerAyahId].
  final int pointerPage;

  /// Total pages the plan aims to finish.
  final int targetPages;

  /// Reader-route coordinates of the pointer (for the open-wird CTA).
  final int readerSurahId;

  /// Ayah number of the pointer inside [readerSurahId].
  final int readerAyahNumber;

  /// Pages to read per day for this plan.
  int get dailyPages => dailyPagesFor(targetPages);

  /// The khatma is complete once the pointer reaches the last page.
  bool get completed => pointerPage >= totalPages;

  /// Pages finished so far.
  int get pagesDone => (pointerPage - firstMushafPage).clamp(0, totalPages);

  /// Progress of the plan as a 0..1 fraction.
  double get fraction => pagesDone / totalPages;

  /// First page of today’s reading chunk.
  int get todayStartPage => pointerPage.clamp(firstMushafPage, totalPages);

  /// Last page of today’s reading chunk.
  int get todayEndPage =>
      (pointerPage + dailyPages - 1).clamp(firstMushafPage, totalPages);

  /// Pages left to finish the plan.
  int get remainingPages => totalPages - pagesDone;

  /// Days left at the current daily pace.
  int get remainingDays => (remainingPages / dailyPages).ceil();
}
