import 'package:flutter/material.dart';

class AppTheme {

  static const Color primaryTeal = Color(0xFF00C9A7); // Turquoise Teal
  static const Color actionBlue = Color(0xFF2962FF); // Royal Blue
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    scaffoldBackgroundColor: white,
    fontFamily: 'Poppins',

    //  Color Scheme
    colorScheme: ColorScheme.light(
      primary: primaryTeal,
      secondary: actionBlue,
      background: white,
      surface: white,
      onPrimary: white,
      onSecondary: white,
      onBackground: black,
      onSurface: black,
    ),

    //  AppBar / Header
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryTeal,
      foregroundColor: white,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: white),
      titleTextStyle: TextStyle(
        color: white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),

    //  Text Theme
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: black,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: black,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: black,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: black,
      ),
    ),

    //  Buttons (Royal Blue Highlight)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: actionBlue,
        foregroundColor: white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 24,
        ),
      ),
    ),

    // Input Fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: black),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryTeal, width: 2),
      ),
      labelStyle: const TextStyle(color: black),
    ),

    //  Icons
    iconTheme: const IconThemeData(
      color: black,
      size: 24,
    ),

    //  Bottom Navigation
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: white,
      selectedItemColor: primaryTeal,
      unselectedItemColor: black,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
    ),
  );
}
