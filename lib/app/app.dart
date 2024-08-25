import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:quran_app/core/theme/theme_app.dart';
import 'package:quran_app/core/utils/app_strings.dart';
import 'package:quran_app/features/quran/presentation/screens/index_screen.dart';

import '../core/common/commons.dart';

class QuranApp extends StatefulWidget {
  const QuranApp({super.key});

  @override
  State<QuranApp> createState() => _QuranAppState();
}

class _QuranAppState extends State<QuranApp> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await readJson();
      await getSettings();
    });
    super.initState();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      debugShowCheckedModeBanner: false,
      title: AppStrings.appName,
      theme: lightMode,
      home: const IndexPage(),
    );
  }
}
