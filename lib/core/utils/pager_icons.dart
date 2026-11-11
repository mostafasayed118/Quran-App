import 'package:flutter/material.dart';

/// The chevron for a month pager, mirrored for the ambient direction.
///
/// Both pager screens use this so "next" means the same thing everywhere and
/// flips with the locale instead of being hardcoded per screen.
IconData pagerChevronFor(TextDirection direction, {required bool next}) {
  final rtl = direction == TextDirection.rtl;
  if (next) return rtl ? Icons.chevron_left : Icons.chevron_right;
  return rtl ? Icons.chevron_right : Icons.chevron_left;
}
