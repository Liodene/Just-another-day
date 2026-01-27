import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// A popup menu button that allows users to select a theme.
class ThemeSelector extends StatelessWidget {
  const ThemeSelector({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
    this.onToggleDarkMode,
  });

  /// The currently selected theme.
  final AppThemeType currentTheme;

  /// Callback when a theme is selected.
  final ValueChanged<AppThemeType> onThemeChanged;

  /// Optional callback to toggle dark mode quickly.
  final VoidCallback? onToggleDarkMode;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Quick dark mode toggle
        if (onToggleDarkMode != null)
          IconButton(
            icon: Icon(
              currentTheme.isDark ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: onToggleDarkMode,
            tooltip: currentTheme.isDark
                ? 'Switch to light mode'
                : 'Switch to dark mode',
          ),
        // Theme selection popup
        PopupMenuButton<AppThemeType>(
          icon: const Icon(Icons.palette),
          tooltip: 'Select theme',
          onSelected: onThemeChanged,
          itemBuilder: (context) => [
            const PopupMenuItem<AppThemeType>(
              enabled: false,
              child: Text(
                'Light Themes',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            ...AppThemeType.values
                .where((t) => !t.isDark)
                .map(
                  (theme) => PopupMenuItem<AppThemeType>(
                    value: theme,
                    child: _ThemeMenuItem(
                      theme: theme,
                      isSelected: theme == currentTheme,
                    ),
                  ),
                ),
            const PopupMenuDivider(),
            const PopupMenuItem<AppThemeType>(
              enabled: false,
              child: Text(
                'Dark Themes',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            ...AppThemeType.values
                .where((t) => t.isDark)
                .map(
                  (theme) => PopupMenuItem<AppThemeType>(
                    value: theme,
                    child: _ThemeMenuItem(
                      theme: theme,
                      isSelected: theme == currentTheme,
                    ),
                  ),
                ),
          ],
        ),
      ],
    );
  }
}

class _ThemeMenuItem extends StatelessWidget {
  const _ThemeMenuItem({required this.theme, required this.isSelected});

  final AppThemeType theme;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          theme.icon,
          size: 20,
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
        ),
        const SizedBox(width: 12),
        Text(
          theme.displayName,
          style: isSelected
              ? TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                )
              : null,
        ),
        if (isSelected) ...[
          const Spacer(),
          Icon(
            Icons.check,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ],
    );
  }
}
