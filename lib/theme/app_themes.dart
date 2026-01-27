import 'package:flutter/material.dart';

/// Enum representing available app themes.
enum AppThemeType {
  /// Light theme with purple accent
  lightPurple('Light Purple', Icons.light_mode),

  /// Light theme with blue accent
  lightBlue('Light Blue', Icons.water_drop),

  /// Light theme with green accent
  lightGreen('Light Green', Icons.eco),

  /// Light theme with orange accent
  lightOrange('Light Orange', Icons.wb_sunny),

  /// Dark theme with purple accent
  darkPurple('Dark Purple', Icons.dark_mode),

  /// Dark theme with blue accent
  darkBlue('Dark Blue', Icons.nightlight),

  /// Dark theme with teal accent
  darkTeal('Dark Teal', Icons.nights_stay),

  /// High contrast dark theme
  darkHighContrast('High Contrast', Icons.contrast);

  const AppThemeType(this.displayName, this.icon);

  /// Human-readable name for the theme
  final String displayName;

  /// Icon representing the theme
  final IconData icon;

  /// Whether this is a dark theme
  bool get isDark => name.startsWith('dark');
}

/// Provides theme data for the application.
class AppThemes {
  AppThemes._();

  /// Get ThemeData for a given theme type.
  static ThemeData getTheme(AppThemeType type) {
    switch (type) {
      case AppThemeType.lightPurple:
        return _lightPurple;
      case AppThemeType.lightBlue:
        return _lightBlue;
      case AppThemeType.lightGreen:
        return _lightGreen;
      case AppThemeType.lightOrange:
        return _lightOrange;
      case AppThemeType.darkPurple:
        return _darkPurple;
      case AppThemeType.darkBlue:
        return _darkBlue;
      case AppThemeType.darkTeal:
        return _darkTeal;
      case AppThemeType.darkHighContrast:
        return _darkHighContrast;
    }
  }

  // Light Themes

  static final ThemeData _lightPurple = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
  );

  static final ThemeData _lightBlue = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
  );

  static final ThemeData _lightGreen = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.green,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
  );

  static final ThemeData _lightOrange = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepOrange,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
  );

  // Dark Themes

  static final ThemeData _darkPurple = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
  );

  static final ThemeData _darkBlue = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
  );

  static final ThemeData _darkTeal = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
  );

  static final ThemeData _darkHighContrast = ThemeData(
    colorScheme: const ColorScheme.dark(
      primary: Colors.white,
      onPrimary: Colors.black,
      secondary: Colors.cyanAccent,
      onSecondary: Colors.black,
      surface: Colors.black,
      onSurface: Colors.white,
      error: Colors.redAccent,
      onError: Colors.black,
    ),
    useMaterial3: true,
  );
}
