import 'package:flutter/material.dart';
import 'package:foap/util/app_config_constants.dart';

enum Font { lato, openSans, poppins, raleway, roboto }

enum DisplayMode { light, dark }

class AppThemeSetting {
  static DisplayMode mode = DisplayMode.light;

  static void setDisplayMode(DisplayMode currentMode) {
    mode = currentMode;
  }
}

class AppTheme {
  static String get fontName {
    switch (fontType) {
      case Font.roboto:
        return 'Roboto';
      case Font.raleway:
        return 'Raleway';
      case Font.poppins:
        return 'Poppins';
      case Font.openSans:
        return 'OpenSans';
      case Font.lato:
        return 'Lato';
    }
  }

  static double iconSize = 20;
  static Font fontType = Font.poppins;

  static ThemeData get lightTheme {
    return _buildTheme(
      brightness: Brightness.light,
      background: AppColorConstants.backgroundColor,
      surface: AppColorConstants.cardColor,
      textColor: AppColorConstants.mainTextColor,
    );
  }

  static ThemeData get darkTheme {
    return _buildTheme(
      brightness: Brightness.dark,
      background: AppColorConstants.backgroundColor,
      surface: AppColorConstants.cardColor,
      textColor: AppColorConstants.mainTextColor,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color textColor,
  }) {
    final Color primary = AppColorConstants.themeColor;
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      primary: primary,
      secondary: AppColorConstants.rdSecondary,
      surface: surface,
    );

    final TextTheme baseTextTheme = ThemeData(
      brightness: brightness,
      fontFamily: fontName,
    ).textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontName,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      canvasColor: background,
      cardColor: surface,
      dividerColor: AppColorConstants.dividerColor,
      iconTheme: IconThemeData(color: AppColorConstants.iconColor, size: 22),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        backgroundColor: background,
        foregroundColor: textColor,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: baseTextTheme.titleMedium?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        elevation: 0,
        selectedItemColor: primary,
        unselectedItemColor:
            AppColorConstants.iconColor.withValues(alpha: 0.62),
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColorConstants.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColorConstants.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 1.4),
        ),
      ),
      textTheme: baseTextTheme.apply(
        bodyColor: textColor,
        displayColor: textColor,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: brightness == Brightness.dark
            ? const Color(0xFF151829)
            : const Color(0xFF101426),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
