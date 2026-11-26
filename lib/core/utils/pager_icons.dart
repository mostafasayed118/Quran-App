import 'package:flutter/material.dart';

/// The chevron for a month pager, in its logical direction.
///
/// Flutter marks `chevron_left` / `chevron_right` with
/// `matchTextDirection: true` and mirrors them itself in RTL, so "next" is
/// always [Icons.chevron_right] and "previous" is always
/// [Icons.chevron_left]. This helper never branches on the locale: branching
/// here would cancel the framework's mirroring and invert the rendered
/// direction.
IconData pagerChevronFor({required bool next}) =>
    next ? Icons.chevron_right : Icons.chevron_left;
