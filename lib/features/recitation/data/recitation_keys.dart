/// Separator between a reciter id and a moshaf id inside a reciter-row id.
const String reciterRowSeparator = '-';

/// Stable key for one downloaded surah: `<rowId>-<surahNumber>`.
String downloadKey(String rowId, int surahNumber) =>
    '$rowId$reciterRowSeparator$surahNumber';
