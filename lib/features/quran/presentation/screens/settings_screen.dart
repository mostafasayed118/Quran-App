import 'package:flutter/material.dart';
import 'package:quran_app/core/common/commons.dart';
import 'package:quran_app/core/utils/app_strings.dart';

import '../../../../core/utils/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppStrings.settings,
        ),
        backgroundColor: AppColors.primaryColor,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text(
                  AppStrings.arabicFontSizeText,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.greenColor,
                  ),
                ),
                Slider(
                    activeColor: AppColors.orangeColor,
                    inactiveColor: AppColors.primaryColor,
                    value: arabicFontSized,
                    max: 40,
                    min: 20,
                    onChanged: (value) {
                      setState(() {
                        arabicFontSized = value;
                      });
                    }),
                Text(
                  "‏ ‏‏ ‏‏‏‏ ‏‏‏‏‏‏ ‏",
                  style:
                      TextStyle(fontFamily: 'quran', fontSize: arabicFontSized),
                  textDirection: TextDirection.rtl,
                ),
                const Padding(
                    padding: EdgeInsets.only(top: 10, bottom: 10),
                    child: Divider()),
                const Text(
                  AppStrings.mushafFontSizeText,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.greenColor,
                  ),
                ),
                Slider(
                    activeColor: AppColors.orangeColor,
                    inactiveColor: AppColors.primaryColor,
                    value: mushafFontSized,
                    max: 50,
                    min: 20,
                    onChanged: (value) {
                      setState(() {
                        mushafFontSized = value;
                      });
                    }),
                Text(
                  "‏ ‏‏ ‏‏‏‏ ‏‏‏‏‏‏ ‏",
                  style:
                      TextStyle(fontFamily: 'quran', fontSize: mushafFontSized),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          arabicFontSized = 28;
                          mushafFontSized = 40;
                        });
                        saveSettings();
                      },
                      child: const Text(AppStrings.reset),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        saveSettings();
                        Navigator.pop(context);
                      },
                      child: const Text(AppStrings.save),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
