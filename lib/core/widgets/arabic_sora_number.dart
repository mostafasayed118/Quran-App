import 'package:flutter/material.dart';
import 'package:quran_app/core/common/commons.dart';

import '../utils/app_colors.dart';
import '../utils/app_strings.dart';

class ArabicSoraNumber extends StatelessWidget {
  const ArabicSoraNumber({super.key, required this.soraNumber});
  final int soraNumber;

  @override
  Widget build(BuildContext context) {
    return Text(
      "\uFD3E${(soraNumber + 1).toString().toArabicNumbers}\uFD3F",
      style: Theme.of(context).textTheme.titleMedium!.copyWith(
          fontWeight: FontWeight.bold,
          fontFamily: AppStrings.meQuranFontFamily,
          fontSize: 25,
          shadows: [
            const Shadow(
              offset: Offset(0.5, 0.5),
              color: AppColors.amberAccentColor,
              blurRadius: 1,
            )
          ]),
    );
  }
}
