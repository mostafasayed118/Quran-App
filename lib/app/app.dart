import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:quran_app/core/common/quran_state.dart';
import 'package:quran_app/core/theme/theme_app.dart';
import 'package:quran_app/core/utils/app_strings.dart';
import 'package:quran_app/features/quran/presentation/screens/index_screen.dart';

class QuranApp extends StatefulWidget {
  const QuranApp({super.key});

  @override
  State<QuranApp> createState() => _QuranAppState();
}

class _QuranAppState extends State<QuranApp> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await quranState.loadJson();
      await quranState.loadSettings();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      debugShowCheckedModeBanner: false,
      title: AppStrings.appName,
      theme: lightMode,
      home: const IndexPage(),
    );
  }
}
