/// Day-key normalization: midnight, local. Never compare raw DateTimes.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
