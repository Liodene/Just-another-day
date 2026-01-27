import 'package:flutter/material.dart';

import 'engine/activity_manager.dart';
import 'engine/game_loop.dart';
import 'models/character.dart';
import 'widgets/widgets.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Just Another Day',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}

/// Main game screen that demonstrates the game loop and activity system.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late final Character _character;
  late final GameLoop _gameLoop;
  late final ActivityManager _activityManager;

  @override
  void initState() {
    super.initState();

    // Initialize character
    _character = Character(name: 'Player');

    // Initialize game loop with this widget as the ticker provider
    _gameLoop = GameLoop(vsync: this);

    // Initialize activity manager
    _activityManager = ActivityManager(
      character: _character,
      gameLoop: _gameLoop,
    );

    // Listen to activity manager changes
    _activityManager.addListener(_onActivityManagerChanged);

    // Start the game loop
    _gameLoop.start();
  }

  void _onActivityManagerChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _activityManager.removeListener(_onActivityManagerChanged);
    _activityManager.dispose();
    _gameLoop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Row(
          children: [
            const Text('Just Another Day'),
            const SizedBox(width: 16),
            GameTimeDisplay(gameTime: _activityManager.gameTime),
          ],
        ),
        actions: [
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
