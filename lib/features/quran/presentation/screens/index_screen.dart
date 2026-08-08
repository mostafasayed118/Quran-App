import 'package:flutter/material.dart';
import 'package:quran_app/core/common/commons.dart';
import 'package:quran_app/core/utils/app_colors.dart';
import 'package:quran_app/core/utils/app_strings.dart';
import 'package:quran_app/core/widgets/arabic_sora_number.dart';
import 'package:quran_app/core/widgets/drawer_widget.dart';

import '../components/surah_bulider.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({super.key});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      drawer: const DrawerWidget(),
      floatingActionButton: FloatingActionButton(
        tooltip: AppStrings.goToBookmark,
        backgroundColor: AppColors.orangeColor,
        onPressed: () async {
          floatingButtonClicked = true;
          if (await readBookMark() == true) {
            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SurahBuilder(
                  arabic: quran[0],
                  surah: bookmarkedSurah - 1,
                  surahName: arabicName[bookmarkedSurah - 1]['name'],
                  ayah: bookmarkedAyah,
                ),
              ),
            );
          }
        },
        child: const Icon(Icons.bookmark, color: AppColors.whiteColor),
      ),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
            AppStrings.quran,
            style: Theme.of(context).textTheme.titleLarge!.copyWith(shadows: [
              const Shadow(
                offset: Offset(1, 1),
                blurRadius: 2.0,
                color: AppColors.blackColor,
              ),
            ])),
        backgroundColor: AppColors.primaryColor,
      ),
      body: quran.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.amberAccentColor,
              ),
            )
          : _buildSurahList(),
    );
  }

  Widget _buildSurahList() {
    return Container(
      color: AppColors.blueColor,
      child: ListView.builder(
        itemCount: 114,
        itemBuilder: (context, i) {
          return Container(
            color: i % 2 == 0
                ? AppColors.offWhiteOneColor
                : AppColors.offWhiteTwoColor,
            child: TextButton(
              child: Row(
                children: [
                  ArabicSoraNumber(soraNumber: i),
                  const SizedBox(width: 5),
                  const Expanded(child: SizedBox()),
                  Text(
                    arabicName[i]['name'],
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      shadows: [
                        const Shadow(
                          offset: Offset(.5, .5),
                          blurRadius: 1.0,
                          color: AppColors.greyColorTwo,
                        )
                      ],
                      fontSize: 28,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
              onPressed: () {
                floatingButtonClicked = false;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => SurahBuilder(
                            arabic: quran[0],
                            surah: i,
                            surahName: arabicName[i]['name'],
                            ayah: 0,
                          )),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
