import 'package:flutter/material.dart';

import '../../../../core/common/commons.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_strings.dart';

Row verseBuilder(int index, previousVerses, dynamic widget) {
  return Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              widget.arabic[index + previousVerses]['aya_text'],
              style: TextStyle(
                fontSize: arabicFontSized,
                fontFamily: AppStrings.arabicFontFamily,
                color: AppColors.blackColor,
              ),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      )
    ],
  );
}
