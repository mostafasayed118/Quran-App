import 'package:flutter/material.dart';
import 'package:quran_app/core/utils/app_strings.dart';

import '../../../../core/utils/app_colors.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Tooltip(
          message: AppStrings.mushafMode,
          child: TextButton(
              onPressed: () {
                
              },
              child: const Icon(
                Icons.chrome_reader_mode,
                color: AppColors.amberAccentColor,
              )),
        ),
      ),
    );
  }
}
