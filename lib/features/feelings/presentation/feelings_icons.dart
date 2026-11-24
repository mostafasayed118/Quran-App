import 'package:flutter/material.dart';

/// Maps catalog icon names to compile-time Material icons.
///
/// The Stitch frame's `mode_fan` and `psychiatry` ligatures are not valid
/// Flutter constants; the catalog uses visually close, valid replacements.
IconData feelingIcon(String name) => switch (name) {
  'air' => Icons.air,
  'water_drop' => Icons.water_drop,
  'person_pin_circle' => Icons.person_pin_circle,
  'explore' => Icons.explore,
  'shield' => Icons.shield,
  'whatshot' => Icons.whatshot,
  'sunny' => Icons.wb_sunny,
  'auto_awesome' => Icons.auto_awesome,
  _ => Icons.favorite_border,
};
