import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran_app/core/utils/app_strings.dart';
import 'package:quran_app/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:quran_app/features/quran/presentation/screens/home_page.dart';

import '../core/common/commons.dart';

List arabic = [];
List quran = [];

Future readJson() async {
  final String response =
      await rootBundle.loadString('assets/json/hafs_smart_v8.json');
  final data = await json.decode(response);
  arabic = data['quran'];

  return quran = [arabic];
}

class QuranApp extends StatefulWidget {
  const QuranApp({super.key});

  @override
  State<QuranApp> createState() => _QuranAppState();
}

class _QuranAppState extends State<QuranApp> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async{
      await readJson();
      await getSettings();
    });
    super.initState();
  }
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppStrings.appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
