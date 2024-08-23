import 'package:flutter/material.dart';
import 'package:quran_app/core/common/commons.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_strings.dart';

class ArabicSoraNumber extends StatelessWidget {
  ArabicSoraNumber({super.key, required this.soraNumber});
  int soraNumber = 1;

  @override
  Widget build(BuildContext context) {
    return Text(
      '\uFD3E${(soraNumber + 1).toString().toArabicNumbers}\uFD3F',
      style: const TextStyle(
          fontFamily: AppStrings.meQuranFontFamily,
          fontSize: 20,
          color: AppColors.blackColor,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              offset: Offset(0.5, 0.5),
              color: AppColors.amberAccentColor,
              blurRadius: 1,
            )
          ]),
    );
  }
}
