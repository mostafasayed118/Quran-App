/// Formats a byte count as megabytes with exactly one decimal place
/// (e.g. `5.5`, `82.0`).
///
/// One decimal everywhere keeps a size label stable as it grows — a pack
/// never jumps from `9.9 MB` to `10 MB` and the column width stops
/// flickering. Callers own the unit and the locale: they append `MB` or
/// pass the number into a localized format string.
String formatMegabytes(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(1);
