import 'package:flutter/material.dart';

import '../constants/colors.dart';

class AppTheme {
  static _border([Color color = AppColors.greyColor]) => OutlineInputBorder(
        borderSide: BorderSide(
          color: color,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(10),
      );

  static final lightThemeMode = ThemeData.light().copyWith(
    //application background color
    scaffoldBackgroundColor: AppColors.whiteModeColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primaryColor,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: const EdgeInsets.all(27),
      floatingLabelStyle: const TextStyle(
        color: AppColors.errorColor,
        //fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      border: _border(),
      enabledBorder: _border(),
      focusedBorder: _border(AppColors.primaryColor),
      errorBorder: _border(AppColors.errorColor),
    ),
  );
}
