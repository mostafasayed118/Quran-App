/// Day-key normalization: midnight, local. Never compare raw DateTimes.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Stable day key (`y-m-d`, no zero padding).
///
/// This shape is persisted by the tracker and consumed by backup merging;
/// changing it breaks installed data.
String dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
