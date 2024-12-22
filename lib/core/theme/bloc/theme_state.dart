import 'package:flutter/material.dart';

import '../../constants/colors.dart';

class ThemeState {
  final ThemeData themeData;

  ThemeState(this.themeData);

  static _border([Color color = AppColors.greyColor]) => OutlineInputBorder(
        borderSide: BorderSide(
          color: color,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(10),
      );

  //light theme
  static ThemeState get lightTheme => ThemeState(
        ThemeData.light().copyWith(
          // Customize dark theme properties

          brightness: Brightness.light,
          primaryColor: AppColors.primaryColor, // Using your main color
// BottomAppBar
          cardColor: AppColors.whiteModeColor, // Cards
          dividerColor: Colors.black12, // General background color
          dialogBackgroundColor: AppColors.whiteModeColor, // Dialogs
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: AppColors.whiteModeColor, // FAB background
            foregroundColor: Colors.black, // FAB foreground
          ),
          navigationBarTheme: const NavigationBarThemeData(
            backgroundColor: AppColors.whiteModeColor, // Bottom navigation bar
            indicatorColor: Colors.black, // Selected item indicator
          ),
          textSelectionTheme: const TextSelectionThemeData(
            cursorColor: Colors.black, // Cursor color
            selectionColor: Colors.black26, // Text selection color
            selectionHandleColor: Colors.black, // Handle color
          ),

          bottomAppBarTheme:
              const BottomAppBarTheme(color: AppColors.whiteModeColor),
          // Define additional properties as needed...
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
        ),
      );

//dark theme
  static ThemeState get darkTheme => ThemeState(
        ThemeData.dark().copyWith(
          // Customize light theme properties
          brightness: Brightness.dark,
          primaryColor: Colors.black,
          scaffoldBackgroundColor: Colors.black, // Scaffold background
          appBarTheme: const AppBarTheme(
            color: Colors.black, // AppBar background
            iconTheme: IconThemeData(color: Colors.white), // AppBar icons
          ), // BottomAppBar
          cardColor: Colors.black, // Cards
          dividerColor:
              Colors.white24, // Background color for widgets like Drawer
          dialogBackgroundColor: Colors.black, // Dialogs
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Colors.black, // FAB background
            foregroundColor: Colors.white, // FAB foreground
          ),
          navigationBarTheme: const NavigationBarThemeData(
            backgroundColor: Colors.black, // Bottom navigation bar
            indicatorColor: Colors.white, // Selected item indicator
          ),
          textSelectionTheme: const TextSelectionThemeData(
            cursorColor: Colors.white, // Cursor color
            selectionColor: Colors.white38, // Text selection color
            selectionHandleColor: Colors.white, // Handle color
          ),

          bottomAppBarTheme: const BottomAppBarTheme(color: Colors.black),
        ),
      );
}
