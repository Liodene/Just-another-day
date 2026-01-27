import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_another_day/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    // Reset SharedPreferences before each test
    SharedPreferences.setMockInitialValues({});
  });

  group('AppThemeType', () {
    test('isDark returns true for dark themes', () {
      expect(AppThemeType.darkPurple.isDark, isTrue);
      expect(AppThemeType.darkBlue.isDark, isTrue);
      expect(AppThemeType.darkTeal.isDark, isTrue);
      expect(AppThemeType.darkHighContrast.isDark, isTrue);
    });

    test('isDark returns false for light themes', () {
      expect(AppThemeType.lightPurple.isDark, isFalse);
      expect(AppThemeType.lightBlue.isDark, isFalse);
      expect(AppThemeType.lightGreen.isDark, isFalse);
      expect(AppThemeType.lightOrange.isDark, isFalse);
    });

    test('all themes have display names', () {
      for (final theme in AppThemeType.values) {
        expect(theme.displayName, isNotEmpty);
      }
    });

    test('all themes have icons', () {
      for (final theme in AppThemeType.values) {
        expect(theme.icon, isNotNull);
      }
    });
  });

  group('AppThemes', () {
    test('getTheme returns valid ThemeData for all theme types', () {
      for (final themeType in AppThemeType.values) {
        final themeData = AppThemes.getTheme(themeType);
        expect(themeData, isA<ThemeData>());
        expect(themeData.useMaterial3, isTrue);
      }
    });

    test('dark themes have dark brightness', () {
      final darkThemes = AppThemeType.values.where((t) => t.isDark);
      for (final themeType in darkThemes) {
        final themeData = AppThemes.getTheme(themeType);
        expect(themeData.brightness, equals(Brightness.dark));
      }
    });

    test('light themes have light brightness', () {
      final lightThemes = AppThemeType.values.where((t) => !t.isDark);
      for (final themeType in lightThemes) {
        final themeData = AppThemes.getTheme(themeType);
        expect(themeData.brightness, equals(Brightness.light));
      }
    });
  });

  group('ThemeProvider', () {
    test('initializes with default light purple theme', () async {
      final provider = ThemeProvider();

      // Wait for async initialization
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(provider.currentTheme, equals(AppThemeType.lightPurple));
      expect(provider.isDarkTheme, isFalse);
      expect(provider.isLoaded, isTrue);

      provider.dispose();
    });

    test('setTheme changes the current theme', () async {
      final provider = ThemeProvider();

      await provider.setTheme(AppThemeType.darkBlue);

      expect(provider.currentTheme, equals(AppThemeType.darkBlue));
      expect(provider.isDarkTheme, isTrue);

      provider.dispose();
    });

    test('setTheme notifies listeners', () async {
      final provider = ThemeProvider();
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.setTheme(AppThemeType.darkPurple);

      expect(notifyCount, greaterThan(0));

      provider.dispose();
    });

    test('setTheme does nothing when setting same theme', () async {
      final provider = ThemeProvider();
      int notifyCount = 0;

      // Wait for initial load
      await Future<void>.delayed(const Duration(milliseconds: 100));

      provider.addListener(() => notifyCount++);

      await provider.setTheme(AppThemeType.lightPurple);

      expect(notifyCount, equals(0));

      provider.dispose();
    });

    test('toggleDarkMode switches between light and dark', () async {
      final provider = ThemeProvider();

      // Start with light theme
      expect(provider.isDarkTheme, isFalse);

      // Toggle to dark
      await provider.toggleDarkMode();
      expect(provider.isDarkTheme, isTrue);

      // Toggle back to light
      await provider.toggleDarkMode();
      expect(provider.isDarkTheme, isFalse);

      provider.dispose();
    });

    test('toggleDarkMode preserves color when possible', () async {
      final provider = ThemeProvider();

      // Set to light blue
      await provider.setTheme(AppThemeType.lightBlue);

      // Toggle to dark - should get dark blue
      await provider.toggleDarkMode();
      expect(provider.currentTheme, equals(AppThemeType.darkBlue));

      // Toggle back - should get light blue
      await provider.toggleDarkMode();
      expect(provider.currentTheme, equals(AppThemeType.lightBlue));

      provider.dispose();
    });

    test('themeData returns correct ThemeData', () async {
      final provider = ThemeProvider();

      await provider.setTheme(AppThemeType.darkTeal);

      final themeData = provider.themeData;
      expect(themeData, equals(AppThemes.getTheme(AppThemeType.darkTeal)));

      provider.dispose();
    });

    test('loads saved theme from SharedPreferences', () async {
      // Set up SharedPreferences with a saved theme
      SharedPreferences.setMockInitialValues({
        'app_theme': AppThemeType.darkBlue.name,
      });

      final provider = ThemeProvider();

      // Wait for async initialization
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(provider.currentTheme, equals(AppThemeType.darkBlue));

      provider.dispose();
    });

    test('saves theme to SharedPreferences when changed', () async {
      final provider = ThemeProvider();

      await provider.setTheme(AppThemeType.lightGreen);

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString('app_theme'),
        equals(AppThemeType.lightGreen.name),
      );

      provider.dispose();
    });
  });
}
