import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF0B0B0B);
  static const surface = Color(0xFF141414);
  static const card = Color(0xFF171717);
  static const cardAlt = Color(0xFF202020);

  static const gold = Color(0xFFD4AF37);
  static const goldDark = Color(0xFFB8942F);

  static const textPrimary = Colors.white;
  static const textSecondary = Colors.white70;
  static const textMuted = Colors.white60;

  static const borderGoldSoft = Color(0x22D4AF37);
  static const borderGoldMedium = Color(0x33D4AF37);
  static const goldTint = Color(0x1AD4AF37);

  static const dangerLowStock = Colors.orangeAccent;

  static const Color glass = Color(0x1AFFFFFF);
  static const Color glassStrong = Color(0x26FFFFFF);
  static const Color glassGold = Color(0x26D4AF37);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.gold,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold,
        surface: AppColors.surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.gold,
          fontSize: 22,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(
          color: AppColors.gold,
        ),
      ),
      cardColor: AppColors.card,
      dividerColor: Colors.white12,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.gold,
        selectionColor: Color(0x55D4AF37),
        selectionHandleColor: AppColors.gold,
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: AppColors.textSecondary,
        filled: true,
        fillColor: const Color(0xFF171717),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: const BorderSide(
            color: AppColors.borderGoldSoft,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: const BorderSide(
            color: AppColors.borderGoldSoft,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: const BorderSide(
            color: AppColors.gold,
            width: 1.15,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: const BorderSide(
            color: AppColors.borderGoldSoft,
            width: 1,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF111111),
        selectedItemColor: AppColors.gold,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}