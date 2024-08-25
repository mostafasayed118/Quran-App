import 'package:flutter/material.dart';
import 'package:quran_app/core/utils/app_assets.dart';
import 'package:quran_app/core/utils/app_colors.dart';
import 'package:quran_app/features/quran/presentation/components/custom_list_tile.dart';
import 'package:quran_app/features/quran/presentation/screens/settings_screen.dart';
import 'package:share_plus/share_plus.dart';

import '../common/commons.dart';
import '../utils/app_strings.dart';

class DrawerWidget extends StatelessWidget {
  const DrawerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.whiteColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.primaryColor,
            ),
            child: Column(
              children: [
                Image.asset(AppAssets.logo, width: 90, height: 90),
                const SizedBox(height: 5),
                Text(
                  AppStrings.quran,
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        color: AppColors.greenColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                      ),
                ),
              ],
            ),
          ),
          CustomListTile(
              title: AppStrings.settings,
              icon: const Icon(Icons.settings, color: AppColors.orangeColor),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsScreen()));
              }),
          const Divider(),
          CustomListTile(
            title: AppStrings.share,
            icon: const Icon(Icons.share, color: AppColors.orangeColor),
            onTap: () {
              Share.share(AppStrings.quranAppLinkDrive.toString());

              Navigator.pop(context);
            },
          ),
          const Divider(),
          const CustomListTile(
              title: AppStrings.rateUs,
              icon: Icon(Icons.star, color: AppColors.orangeColor),
              onTap: launchQuranAppLink)
        ],
      ),
    );
  }
}
