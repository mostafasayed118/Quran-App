import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(useMaterial3: true);
  static ThemeData get dark => ThemeData(useMaterial3: true, brightness: Brightness.dark);
}
