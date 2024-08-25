import 'package:flutter/material.dart';
import 'package:quran_app/core/utils/app_strings.dart';

class ReturnBasmala extends StatelessWidget {
  const ReturnBasmala({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Text(
            'بسم الله الرحمن الرحيم',
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppStrings.meQuranFontFamily,
                ),
            textDirection: TextDirection.rtl,
          ),
        ),
      ],
    );
  }
}
