import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class QuranYahdiApp extends StatelessWidget {
  const QuranYahdiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quran Yahdi',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const Scaffold(
        body: Center(child: Text('قرآن يَهدي')),
      ),
    );
  }
}
