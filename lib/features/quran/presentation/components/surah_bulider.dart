import 'package:flutter/material.dart';
import 'package:quran_app/core/common/commons.dart';
import 'package:quran_app/core/utils/app_strings.dart';
import 'package:quran_app/features/quran/presentation/components/return_basmala.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/utils/app_colors.dart';

final ItemScrollController itemScrollController = ItemScrollController();
final ItemPositionsListener itemPositionsListener =
    ItemPositionsListener.create();

bool floatingButtonClicked = true;

class SurahBuilder extends StatefulWidget {
  final surah;
  final arabic;
  final surahName;
  int ayah;

  SurahBuilder({
    super.key,
    this.surah,
    this.arabic,
    this.surahName,
    required this.ayah,
  });

  @override
  _SurahBuilderState createState() => _SurahBuilderState();
}

class _SurahBuilderState extends State<SurahBuilder> {
  bool isView = true;
  @override
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) => jumpToAyah());
    super.initState();
  }

  jumpToAyah() {
    if (floatingButtonClicked) {
      itemScrollController.scrollTo(
          index: widget.ayah,
          duration: const Duration(seconds: 1),
          curve: Curves.easeInOutCubic);
    }
    floatingButtonClicked = false;
  }

  saveBookMark(surah, ayah) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('surah', surah);
    await prefs.setInt('ayah', ayah);
  }

  Row verseBuilder(int index, previousVerses) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                widget.arabic[index + previousVerses]['aya_text'],
                style: TextStyle(
                  fontSize: AppStrings.arabicFontSized,
                  fontFamily: AppStrings.arabicFontFamily,
                  color: AppColors.blackColor,
                ),
              ),
              Column(
                children: [
                  Text(
                    widget.arabic[index + previousVerses]['aya_number']
                        .toString()
                        .toArabicNumbers,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.blackColor,
                    ),
                  ),
                  Text(
                    widget.arabic[index + previousVerses]['sora_number']
                        .toString()
                        .toArabicNumbers,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.blackColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
      ],
    );
  }

  SafeArea SingleSuraBuilder(LenghtOfSura) {
    String fullSura = '';
    int previousVerses = 0;
    if (widget.surah + 1 != 1) {
      for (int i = widget.surah - 1; i >= 0; i--) {
        previousVerses += previousVerses + noOfVerses[i];
      }
    }
    if (!isView) {
      for (int i = 0; i < LenghtOfSura; i++) {
        fullSura += widget.arabic[i + previousVerses]['aya_text'];
      }
    }

    return SafeArea(
      child: Container(
          color: AppColors.whiteColor,
          child: isView
              ? ScrollablePositionedList.builder(
                  itemCount: LenghtOfSura,
                  itemScrollController: itemScrollController,
                  itemPositionsListener: itemPositionsListener,
                  itemBuilder: (BuildContext context, int index) {
                    return Column(
                      children: [
                        (index != 0 ||
                                (widget.surah == 0) ||
                                (widget.surah == 8))
                            ? const Text('')
                            : const ReturnBasmala(),
                        Container(
                          color: index % 2 == 0
                              ? AppColors.whiteColor
                              : AppColors.greyColor,
                          child: PopupMenuButton(
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: verseBuilder(index, previousVerses),
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
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      AppStrings.bookMark,
                                      style: TextStyle(
                                          color: AppColors.blackColor),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                onTap: () {},
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.share,
                                      color: AppColors.amberAccentColor,
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      AppStrings.share,
                                      style: TextStyle(
                                          color: AppColors.blackColor),
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
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Text(
                                  fullSura,
                                  style: TextStyle(
                                      fontSize: AppStrings.mushafFontSized,
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
                )),
    );
  }

  @override
  Widget build(BuildContext context) {
    int LengthOfSura = noOfVerses[widget.surah];
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
          style: const TextStyle(
            color: AppColors.whiteColor,
            fontFamily: AppStrings.arabicFontFamily,
            shadows: [
              Shadow(
                offset: Offset(1, 1),
                color: AppColors.blackColor,
                blurRadius: 2,
              )
            ],
          ),
          textAlign: TextAlign.center,
        ),
        backgroundColor: AppColors.primaryColor,
      ),
      body: SingleSuraBuilder(LengthOfSura),
    );
  }
}
