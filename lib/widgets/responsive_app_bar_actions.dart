import 'package:flutter/material.dart';

import '../engine/save_manager.dart';
import '../models/game_time.dart';
import '../theme/theme.dart';
import 'game_time_display.dart';
import 'save_menu_button.dart';
import 'theme_selector.dart';

/// Minimum width to show all actions expanded.
const double _expandedBreakpoint = 600;

/// Responsive app bar actions that collapse into a menu on narrow screens.
class ResponsiveAppBarActions extends StatelessWidget {
  const ResponsiveAppBarActions({
    super.key,
    required this.gameTime,
    required this.themeProvider,
    required this.saveManager,
    required this.onImport,
    required this.onReset,
    required this.isPaused,
    required this.onTogglePause,
  });

  /// The game time to display.
  final GameTime gameTime;

  /// The theme provider for theme selection.
  final ThemeProvider themeProvider;

  /// The save manager for save/load operations.
  final SaveManager saveManager;

  /// Callback when a save is imported.
  final ValueChanged<GameSaveData> onImport;

  /// Callback when the save is reset.
  final VoidCallback onReset;

  /// Whether the game is paused.
  final bool isPaused;

  /// Callback to toggle pause state.
  final VoidCallback onTogglePause;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isExpanded = screenWidth >= _expandedBreakpoint;

    if (isExpanded) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GameTimeDisplay(gameTime: gameTime),
          ),
          ThemeSelector(
            currentTheme: themeProvider.currentTheme,
            onThemeChanged: themeProvider.setTheme,
            onToggleDarkMode: themeProvider.toggleDarkMode,
          ),
          SaveMenuButton(
            saveManager: saveManager,
            onImport: onImport,
            onReset: onReset,
          ),
          IconButton(
            icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
            onPressed: onTogglePause,
            tooltip: isPaused ? 'Resume' : 'Pause',
          ),
        ],
      );
    }

    // Collapsed view for narrow screens
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Always show game time and pause button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GameTimeDisplay(gameTime: gameTime),
        ),
        IconButton(
          icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
          onPressed: onTogglePause,
          tooltip: isPaused ? 'Resume' : 'Pause',
        ),
        // Overflow menu for other actions
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          tooltip: 'More options',
          onSelected: (value) => _handleMenuSelection(context, value),
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              value: 'toggle_dark_mode',
              child: Row(
                children: [
                  Icon(
                    themeProvider.isDarkTheme
                        ? Icons.light_mode
                        : Icons.dark_mode,
                  ),
                  const SizedBox(width: 12),
                  Text(themeProvider.isDarkTheme ? 'Light mode' : 'Dark mode'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'theme',
              child: Row(
                children: [
                  Icon(Icons.palette),
                  SizedBox(width: 12),
                  Text('Change theme'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'save',
              child: Row(
                children: [
                  Icon(Icons.save),
                  SizedBox(width: 12),
                  Text('Save game'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.upload),
                  SizedBox(width: 12),
                  Text('Export save'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'import',
              child: Row(
                children: [
                  Icon(Icons.download),
                  SizedBox(width: 12),
                  Text('Import save'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'reset',
              child: Row(
                children: [
                  Icon(Icons.delete_forever, color: Colors.red[700]),
                  const SizedBox(width: 12),
                  Text('Reset save', style: TextStyle(color: Colors.red[700])),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handleMenuSelection(BuildContext context, String value) async {
    final saveActions = SaveMenuActions(
      saveManager: saveManager,
      onImport: onImport,
      onReset: onReset,
    );

    switch (value) {
      case 'toggle_dark_mode':
        themeProvider.toggleDarkMode();
      case 'theme':
        _showThemeDialog(context);
      case 'save':
      case 'export':
      case 'import':
      case 'reset':
        await saveActions.handleSelection(context, value);
    }
  }

  void _showThemeDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
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
                    (theme) => ListTile(
                      leading: Icon(theme.icon),
                      title: Text(theme.displayName),
                      trailing: theme == themeProvider.currentTheme
                          ? const Icon(Icons.check)
                          : null,
                      onTap: () {
                        themeProvider.setTheme(theme);
                        Navigator.pop(context);
                      },
                    ),
                  ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
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
                    (theme) => ListTile(
                      leading: Icon(theme.icon),
                      title: Text(theme.displayName),
                      trailing: theme == themeProvider.currentTheme
                          ? const Icon(Icons.check)
                          : null,
                      onTap: () {
                        themeProvider.setTheme(theme);
                        Navigator.pop(context);
                      },
                    ),
                  ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

}
