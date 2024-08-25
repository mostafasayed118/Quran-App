import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/app_strings.dart';

ThemeData lightMode = ThemeData(
  primaryColor: AppColors.primaryColor,
  colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryColor),
  useMaterial3: true,
  brightness: Brightness.light,
  fontFamily: AppStrings.arabicFontFamily,
  textTheme: const TextTheme(
    titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.blackColor,
        fontFamily: AppStrings.arabicFontFamily),
    titleMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.blackColor,
        fontFamily: AppStrings.arabicFontFamily),
    titleSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.blackColor,
        fontFamily: AppStrings.arabicFontFamily),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.primaryColor,
    centerTitle: true,
  ),
  scaffoldBackgroundColor: AppColors.whiteColor,
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.whiteColor,
    selectedItemColor: AppColors.primaryColor,
    unselectedItemColor: AppColors.blackColor,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStateProperty.all(AppColors.primaryColor),
      foregroundColor: WidgetStateProperty.all(AppColors.orangeColor),
      textStyle: WidgetStateProperty.all(
        const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: AppStrings.arabicFontFamily,
            color: AppColors.blackColor),
      ),
      elevation: WidgetStateProperty.all(0),
      shadowColor: WidgetStateProperty.all(Colors.transparent),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: ButtonStyle(
      foregroundColor: WidgetStateProperty.all(AppColors.orangeColor),
      textStyle: WidgetStateProperty.all(
        const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: AppStrings.arabicFontFamily,
            color: AppColors.blackColor),
      ),
    ),
  ),
  iconTheme: const IconThemeData(
    color: AppColors.blackColor,
  ),
);

ThemeData darkMode = ThemeData(
  primaryColor: AppColors.primaryColor,
  colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryColor),
  useMaterial3: true,
  brightness: Brightness.dark,
  fontFamily: AppStrings.arabicFontFamily,
  textTheme: const TextTheme(
    titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.whiteColor,
        fontFamily: AppStrings.arabicFontFamily),
    titleMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.whiteColor,
        fontFamily: AppStrings.arabicFontFamily),
    titleSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.whiteColor,
        fontFamily: AppStrings.arabicFontFamily),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.primaryColor,
    centerTitle: true,
  ),
  scaffoldBackgroundColor: AppColors.whiteColor,
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.whiteColor,
    selectedItemColor: AppColors.primaryColor,
    unselectedItemColor: AppColors.blackColor,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStateProperty.all(AppColors.primaryColor),
      foregroundColor: WidgetStateProperty.all(AppColors.whiteColor),
      textStyle: WidgetStateProperty.all(
        const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: AppStrings.arabicFontFamily),
      ),
      elevation: WidgetStateProperty.all(0),
      shadowColor: WidgetStateProperty.all(Colors.transparent),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: ButtonStyle(
      foregroundColor: WidgetStateProperty.all(AppColors.primaryColor),
      textStyle: WidgetStateProperty.all(
        const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: AppStrings.arabicFontFamily),
      ),
    ),
  ),
  iconTheme: const IconThemeData(
    color: AppColors.blackColor,
  ),
);
