import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_themes.dart';

/// Key used to store theme preference in SharedPreferences.
const String _themePreferenceKey = 'app_theme';

/// Provider that manages the application theme state.
///
/// This class handles:
/// - Loading saved theme preference from storage
/// - Saving theme preference when changed
/// - Notifying listeners when theme changes
class ThemeProvider extends ChangeNotifier {
  ThemeProvider() {
    _loadThemePreference();
  }

  AppThemeType _currentTheme = AppThemeType.lightPurple;
  bool _isLoaded = false;

  /// The currently selected theme type.
  AppThemeType get currentTheme => _currentTheme;

  /// The ThemeData for the current theme.
  ThemeData get themeData => AppThemes.getTheme(_currentTheme);

  /// Whether the theme preference has been loaded from storage.
  bool get isLoaded => _isLoaded;

  /// Whether the current theme is a dark theme.
  bool get isDarkTheme => _currentTheme.isDark;

  /// Set the current theme and persist the preference.
  Future<void> setTheme(AppThemeType theme) async {
    if (_currentTheme == theme) return;

    _currentTheme = theme;
    notifyListeners();

    await _saveThemePreference();
  }

  /// Toggle between light and dark mode, preserving color preference when possible.
  Future<void> toggleDarkMode() async {
    final AppThemeType newTheme;

    if (_currentTheme.isDark) {
      // Switch to light version
      switch (_currentTheme) {
        case AppThemeType.darkPurple:
          newTheme = AppThemeType.lightPurple;
        case AppThemeType.darkBlue:
          newTheme = AppThemeType.lightBlue;
        case AppThemeType.darkTeal:
          newTheme = AppThemeType.lightGreen;
        case AppThemeType.darkHighContrast:
          newTheme = AppThemeType.lightPurple;
        default:
          newTheme = AppThemeType.lightPurple;
      }
    } else {
      // Switch to dark version
      switch (_currentTheme) {
        case AppThemeType.lightPurple:
          newTheme = AppThemeType.darkPurple;
        case AppThemeType.lightBlue:
          newTheme = AppThemeType.darkBlue;
        case AppThemeType.lightGreen:
          newTheme = AppThemeType.darkTeal;
        case AppThemeType.lightOrange:
          newTheme = AppThemeType.darkPurple;
        default:
          newTheme = AppThemeType.darkPurple;
      }
    }

    await setTheme(newTheme);
  }

  /// Load the theme preference from storage.
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeName = prefs.getString(_themePreferenceKey);

      if (themeName != null) {
        final theme = AppThemeType.values.where((t) => t.name == themeName).firstOrNull;
        if (theme != null) {
          _currentTheme = theme;
        }
      }
    } catch (e) {
      // If loading fails, use default theme
      debugPrint('Failed to load theme preference: $e');
    }

    _isLoaded = true;
    notifyListeners();
  }

  /// Save the current theme preference to storage.
  Future<void> _saveThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themePreferenceKey, _currentTheme.name);
    } catch (e) {
      debugPrint('Failed to save theme preference: $e');
    }
  }
}
