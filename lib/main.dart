import 'package:flutter/material.dart';

import 'engine/activity_manager.dart';
import 'engine/game_loop.dart';
import 'engine/save_manager.dart';
import 'models/character.dart';
import 'models/game_time.dart';
import 'theme/theme.dart';
import 'widgets/widgets.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final ThemeProvider _themeProvider;

  @override
  void initState() {
    super.initState();
    _themeProvider = ThemeProvider();
    _themeProvider.addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _themeProvider.removeListener(_onThemeChanged);
    _themeProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Just Another Day',
      theme: _themeProvider.themeData,
      home: GameScreen(themeProvider: _themeProvider),
    );
  }
}

/// Main game screen that demonstrates the game loop and activity system.
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.themeProvider,
  });

  /// The theme provider for managing app theme.
  final ThemeProvider themeProvider;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late final Character _character;
  late final GameLoop _gameLoop;
  late final ActivityManager _activityManager;
  late final SaveManager _saveManager;
  late final GameTime _gameTime;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // Initialize character
    _character = Character(name: 'Player');

    // Initialize game time
    _gameTime = GameTime();

    // Initialize game loop with this widget as the ticker provider
    _gameLoop = GameLoop(vsync: this);

    // Initialize activity manager
    _activityManager = ActivityManager(
      character: _character,
      gameLoop: _gameLoop,
      gameTime: _gameTime,
    );

    // Initialize save manager
    _saveManager = SaveManager();
    _saveManager.initialize(character: _character, gameTime: _gameTime);

    // Listen to activity manager changes
    _activityManager.addListener(_onActivityManagerChanged);

    // Load saved game and start
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    // Try to load existing save
    final saveData = await _saveManager.load();
    if (saveData != null) {
      _character.restoreFrom(saveData.character);
      _gameTime.restoreFrom(saveData.gameTime);
    }

    // Start autosave (every 30 seconds)
    _saveManager.startAutosave();

    // Start the game loop
    _gameLoop.start();

    setState(() {
      _isLoading = false;
    });
  }

  void _handleImport(GameSaveData saveData) {
    // Pause game during import
    _gameLoop.pause();
    _activityManager.stopActivity();

    // Restore state
    _character.restoreFrom(saveData.character);
    _gameTime.restoreFrom(saveData.gameTime);

    // Save immediately after import
    _saveManager.save();

    // Resume game
    _gameLoop.resume();

    setState(() {});
  }

  void _onActivityManagerChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _activityManager.removeListener(_onActivityManagerChanged);
    _activityManager.dispose();
    _saveManager.dispose();
    _gameLoop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Just Another Day'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Just Another Day'),
        actions: [
          ThemeSelector(
            currentTheme: widget.themeProvider.currentTheme,
            onThemeChanged: widget.themeProvider.setTheme,
            onToggleDarkMode: widget.themeProvider.toggleDarkMode,
          ),
          SaveMenuButton(
            saveManager: _saveManager,
            onImport: _handleImport,
          ),
          IconButton(
            icon: Icon(_gameLoop.isPaused ? Icons.play_arrow : Icons.pause),
            onPressed: _togglePause,
            tooltip: _gameLoop.isPaused ? 'Resume' : 'Pause',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StatsCard(character: _character),
                    const SizedBox(height: 16),
                    ActivityProgressCard(
                      progress: _activityManager.currentProgress,
                      autoRepeat: _activityManager.autoRepeat,
                      onAutoRepeatChanged: (value) {
                        _activityManager.autoRepeat = value;
                      },
                      onStopActivity: _activityManager.stopActivity,
                    ),
                    const SizedBox(height: 16),
                    ActivitiesCard(
                      activities: _activityManager.getAllActivities(),
                      character: _character,
                      currentActivityId: _activityManager.currentActivity?.id,
                      hasActiveActivity: _activityManager.hasActiveActivity,
                      onStartActivity: _activityManager.startActivity,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _togglePause() {
    setState(() {
      if (_gameLoop.isPaused) {
        _gameLoop.resume();
      } else {
        _gameLoop.pause();
      }
    });
  }
}
