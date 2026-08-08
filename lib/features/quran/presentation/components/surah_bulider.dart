import 'package:flutter/material.dart';
import 'package:quran_app/core/common/commons.dart';
import 'package:quran_app/core/utils/app_strings.dart';
import 'package:quran_app/features/quran/presentation/components/return_basmala.dart';
import 'package:quran_app/features/quran/presentation/components/verse_builder.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../../core/utils/app_colors.dart';

class SurahBuilder extends StatefulWidget {
  final dynamic surah;
  final dynamic arabic;
  final dynamic surahName;
  final int ayah;

  const SurahBuilder({
    super.key,
    this.surah,
    this.arabic,
    this.surahName,
    required this.ayah,
  });

  @override
  State<SurahBuilder> createState() => _SurahBuilderState();
}

class _SurahBuilderState extends State<SurahBuilder> {
  bool isView = true;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) => jumpToAyah());
    super.initState();
  }

  void jumpToAyah() {
    if (floatingButtonClicked) {
      itemScrollController.scrollTo(
          index: widget.ayah,
          duration: const Duration(seconds: 2),
          curve: Curves.easeInOutCubic);
    }
    floatingButtonClicked = false;
  }

  SafeArea _buildSurahContent(int lengthOfSurah) {
    String fullSura = '';
    int previousVerses = 0;
    if (widget.surah + 1 != 1) {
      for (int i = widget.surah - 1; i >= 0; i--) {
        previousVerses = previousVerses + noOfVerses[i];
      }
    }
    if (!isView) {
      for (int i = 0; i < lengthOfSurah; i++) {
        fullSura += widget.arabic[i + previousVerses]['aya_text'];
      }
    }

    return SafeArea(
      child: Container(
        color: AppColors.whiteColor,
        child: isView
            ? ScrollablePositionedList.builder(
                itemCount: lengthOfSurah,
                itemScrollController: itemScrollController,
                itemPositionsListener: itemPositionsListener,
                itemBuilder: (BuildContext context, int index) {
                  return Column(
                    children: [
                      (index != 0 || (widget.surah == 0) || (widget.surah == 8))
                          ? const Text('')
                          : const ReturnBasmala(),
                      const SizedBox(height: 20),
                      Container(
                        color: index % 2 == 0
                            ? AppColors.whiteColor
                            : AppColors.offWhiteOneColor,
                        child: PopupMenuButton(
                          color: AppColors.primaryColor,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: verseBuilder(index, previousVerses, widget),
                          ),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              onTap: () {
                                saveBookMark(widget.surah + 1, index);
                                setState(() {
                                  isView = !isView;
                                });
                              },
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.bookmark,
                                    color: AppColors.amberAccentColor,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    AppStrings.bookMark,
                                    style:
                                        TextStyle(color: AppColors.blackColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              )
            : ListView(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            widget.surah + 1 != 1 && widget.surah + 1 != 9
                                ? const ReturnBasmala()
                                : const Text(''),
                            const SizedBox(height: 20),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text(
                                fullSura,
                                style: TextStyle(
                                    fontSize: mushafFontSized,
                                    fontFamily: AppStrings.arabicFontFamily,
                                    color: AppColors.blackColor),
                                textAlign: TextAlign.center,
                                textDirection: TextDirection.rtl,
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  )
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int lengthOfSurah = noOfVerses[widget.surah];
    return Scaffold(
      appBar: AppBar(
        leading: Tooltip(
          message: AppStrings.mushafMode,
          child: TextButton(
            onPressed: () {
              setState(() {
                isView = !isView;
              });
            },
            child: const Icon(
              Icons.chrome_reader_mode,
              color: AppColors.amberAccentColor,
            ),
          ),
        ),
        centerTitle: true,
        title: Text(
          widget.surahName,
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
              color: AppColors.greenColor,
              fontWeight: FontWeight.bold,
              fontSize: 25),
          textAlign: TextAlign.center,
        ),
        backgroundColor: AppColors.primaryColor,
      ),
      body: _buildSurahContent(lengthOfSurah),
    );
  }
}
