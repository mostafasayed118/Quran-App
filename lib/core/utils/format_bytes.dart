/// Formats a byte count as megabytes with exactly one decimal place
/// (e.g. `5.5`, `82.0`).
///
/// One decimal everywhere keeps a size label stable as it grows — a pack
/// never jumps from `9.9 MB` to `10 MB` and the column width stops
/// flickering. Callers own the unit and the locale: they append `MB` or
/// pass the number into a localized format string.
String formatMegabytes(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(1);

/// Formats a value already expressed in megabytes.
///
/// A whole number drops the decimal (`2` instead of `2.0`); a fractional one
/// keeps a single decimal (`2.5`). Used where the catalog already carries the
/// size in MB, so it must not pretend to a precision the source does not have.
String formatMegabytesValue(double megabytes) =>
    megabytes == megabytes.roundToDouble()
        ? megabytes.toStringAsFixed(0)
        : megabytes.toStringAsFixed(1);
