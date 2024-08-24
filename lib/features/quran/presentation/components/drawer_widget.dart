import 'package:flutter/material.dart';
import 'package:quran_app/core/utils/app_assets.dart';
import 'package:quran_app/core/utils/app_colors.dart';
import 'package:quran_app/features/quran/presentation/screens/settings_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/app_strings.dart';

class DrawerWidget extends StatelessWidget {
  const DrawerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.primaryColor,
            ),
            child: Column(
              children: [
                Image.asset(AppAssets.logo, width: 100, height: 100),
                const Text(
                  AppStrings.appName,
                  style: TextStyle(color: AppColors.whiteColor),
                ),
              ],
            ),
          ),
          ListTile(
            title: const Text(AppStrings.settings),
            leading: const Icon(Icons.settings),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SettingsScreen()));
            },
          ),
           ListTile(
            title: Text(AppStrings.share),
            leading: const Icon(Icons.share),
            onTap: () {
              Share.share(AppStrings.quranAppLink.toString());
               
              Navigator.pop(context);
            },
          ),
           ListTile(
            title: Text(AppStrings.rateUs),
            leading: const Icon(Icons.star),
            onTap: () async{
              if(!await launchUrl(AppStrings.quranAppLink,mode: LaunchMode.externalApplication)) {
                throw 'Could not launch ${AppStrings.quranAppLink}';
              }
            },
          ),
        ],
      ),
    );
  }
}
