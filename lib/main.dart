import 'package:flutter/material.dart';

import 'engine/activity_manager.dart';
import 'engine/game_loop.dart';
import 'engine/save_manager.dart';
import 'models/activity.dart';
import 'models/character.dart';
import 'models/game_time.dart';
import 'models/offline_progress.dart';
import 'models/planned_activity.dart';
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
  const GameScreen({super.key, required this.themeProvider});

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
  bool _isDayEndDialogShowing = false;

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
    _saveManager.initialize(
      character: _character,
      gameTime: _gameTime,
      planner: _activityManager.planner,
    );

    // Listen to activity manager changes (only rebuild when needed)
    // We don't use addListener here to avoid full rebuilds every frame

    // Set up day expired callback
    _activityManager.onDayExpired = _onDayExpired;

    // Load saved game and start
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    try {
      // Try to load existing save
      final saveData = await _saveManager.load();
      if (saveData != null) {
        _character.restoreFrom(saveData.character);
        _gameTime.restoreFrom(saveData.gameTime);
        // Restore planner queue if available
        if (saveData.plannerQueue != null) {
          _activityManager.planner.restoreFromJson(saveData.plannerQueue!);
        }

        // Check for offline progress
        final offlineProgress = OfflineProgressData.calculate(
          saveData.savedAt,
          _gameTime,
          _character,
          timeMultiplier: _gameTime.timeMultiplier,
        );

        if (offlineProgress != null) {
          // Schedule modal to show after first frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showOfflineProgressModal(offlineProgress);
          });
        }
      }

      // Start autosave (every 30 seconds)
      _saveManager.startAutosave();

      // Start the game loop
      _gameLoop.start();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      // If loading fails, show error and start fresh
      debugPrint('Error initializing game: $e');

      // Start autosave and game loop anyway
      _saveManager.startAutosave();
      _gameLoop.start();

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showOfflineProgressModal(OfflineProgressData progressData) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => OfflineProgressModal(
        progressData: progressData,
        onContinue: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _handleImport(GameSaveData saveData) {
    // Pause game during import
    _gameLoop.pause();
    _activityManager.stopActivity();

    // Restore state
    _character.restoreFrom(saveData.character);
    _gameTime.restoreFrom(saveData.gameTime);
    // Restore planner queue if available
    if (saveData.plannerQueue != null) {
      _activityManager.planner.restoreFromJson(saveData.plannerQueue!);
    }

    // Save immediately after import
    _saveManager.save();

    // Resume game
    _gameLoop.resume();

    setState(() {});
  }

  void _onDayExpired(Map<StatType, double> dailyGains) {
    // Show the day end modal (only once)
    if (!_isDayEndDialogShowing) {
      _isDayEndDialogShowing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showDayEndModal(dailyGains);
      });
    }
  }

  void _showDayEndModal(Map<StatType, double> dailyGains) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DayEndModal(
        dayCount: _gameTime.dayCount,
        dailyGains: dailyGains,
        onStartNewDay: () {
          _activityManager.startNewDay();
          _isDayEndDialogShowing = false;
        },
      ),
    );
  }

  void _handleReset() {
    // Stop any running activity
    _activityManager.stopActivity();

    // Reset character to default state
    _character.restoreFrom(Character(name: 'Player'));

    // Reset game time
    _gameTime.reset();

    // Clear daily completions
    _activityManager.clearDailyCompletions();

    // Delete saved data
    _saveManager.deleteSave();

    // Resume game loop if paused
    if (_gameLoop.isPaused) {
      _gameLoop.resume();
    }

    setState(() {});
  }

  @override
  void dispose() {
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
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Just Another Day'),
        actions: [
          ResponsiveAppBarActions(
            gameTime: _activityManager.gameTime,
            themeProvider: widget.themeProvider,
            saveManager: _saveManager,
            onImport: _handleImport,
            onReset: _handleReset,
            isPaused: _gameLoop.isPaused,
            onTogglePause: _togglePause,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StatsCard(character: _character),
                    const SizedBox(height: 16),
                    ListenableBuilder(
                      listenable: _activityManager,
                      builder: (context, child) => ActivityProgressCard(
                        progress: _activityManager.currentProgress,
                        autoRepeat: _activityManager.autoRepeat,
                        onAutoRepeatChanged: (value) {
                          _activityManager.autoRepeat = value;
                        },
                        onStopActivity: _activityManager.stopActivity,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListenableBuilder(
                      listenable: _activityManager,
                      builder: (context, child) => ActivityPlannerCard(
                        activityManager: _activityManager,
                        character: _character,
                        onAddActivity: _showAddPlannedActivityDialog,
                        onCancelPlan: _showCancelPlanDialog,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ActivitiesCard(
                      activities: _activityManager.getAllActivities(),
                      character: _character,
                      currentActivityId: _activityManager.currentActivity?.id,
                      hasActiveActivity: _activityManager.hasActiveActivity,
                      onStartActivity: _handleStartActivity,
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

  Future<void> _showAddPlannedActivityDialog() async {
    final result = await showDialog<PlannedActivity>(
      context: context,
      builder: (context) => AddPlannedActivityDialog(
        activities: _activityManager.getAllActivities(),
        character: _character,
        activityManager: _activityManager,
      ),
    );

    if (result != null) {
      _activityManager.planner.addPlannedActivity(result);
    }
  }

  Future<void> _showCancelPlanDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const CancelPlanDialog(),
    );

    if (confirmed ?? false) {
      _activityManager.cancelPlan();
    }
  }

  Future<void> _handleStartActivity(Activity activity) async {
    // If there's an active plan, show confirmation dialog
    if (_activityManager.planner.hasPlannedActivities) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => SwitchActivityDialog(newActivity: activity),
      );

      if (confirmed != true) {
        return;
      }

      // Cancel the plan and start the new activity
      _activityManager.cancelPlan();
    }

    _activityManager.startActivity(activity, force: true);
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
