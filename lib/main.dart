import 'package:flutter/material.dart';

import 'engine/activity_manager.dart';
import 'engine/game_loop.dart';
import 'models/character.dart';

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
        title: const Text('Just Another Day'),
        actions: [
          // Game loop control
          IconButton(
            icon: Icon(_gameLoop.isPaused ? Icons.play_arrow : Icons.pause),
            onPressed: () {
              setState(() {
                if (_gameLoop.isPaused) {
                  _gameLoop.resume();
                } else {
                  _gameLoop.pause();
                }
              });
            },
            tooltip: _gameLoop.isPaused ? 'Resume' : 'Pause',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Character stats section
            _buildStatsCard(),
            const SizedBox(height: 16),

            // Current activity progress
            _buildProgressCard(),
            const SizedBox(height: 16),

            // Activity selection
            Expanded(
              child: _buildActivitiesCard(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final stats = _character.stats;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _character.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: _character.level > 1
                          ? () => setState(() => _character.level--)
                          : null,
                      iconSize: 20,
                    ),
                    Text(
                      'Lv.${_character.level}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => setState(() => _character.level++),
                      iconSize: 20,
                    ),
                  ],
                ),
              ],
            ),
            Text(
              'Difficulty: ${_character.difficultyCoefficient.toStringAsFixed(2)}x',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            _buildStatRow('Strength', stats.strength, Colors.red),
            _buildStatRow('Intelligence', stats.intelligence, Colors.blue),
            _buildStatRow('Endurance', stats.endurance, Colors.green),
            _buildStatRow('Charisma', stats.charisma, Colors.orange),
            _buildStatRow('Agility', stats.agility, Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String name, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(name),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: (value / 100).clamp(0.0, 1.0),
              backgroundColor: color.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: Text(
              value.toStringAsFixed(1),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final progress = _activityManager.currentProgress;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Activity',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Row(
                  children: [
                    const Text('Auto-repeat'),
                    Switch(
                      value: _activityManager.autoRepeat,
                      onChanged: (value) {
                        _activityManager.autoRepeat = value;
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (progress == null)
              const Text(
                'No activity in progress. Select an activity below.',
                style: TextStyle(fontStyle: FontStyle.italic),
              )
            else ...[
              Text(
                progress.activity.name,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress.progress,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${(progress.progress * 100).toStringAsFixed(1)}%'),
                  Text(
                    '${progress.remainingTime.toStringAsFixed(1)}s remaining',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  _activityManager.stopActivity();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Stop Activity'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActivitiesCard() {
    final activities = _activityManager.getAllActivities();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activities',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  final meetsRequirements =
                      activity.meetsRequirements(_character.stats);
                  final isCurrentActivity =
                      _activityManager.currentActivity?.id == activity.id;

                  return Card(
                    color: isCurrentActivity
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    child: ListTile(
                      title: Text(activity.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(activity.description),
                          const SizedBox(height: 4),
                          Text(
                            'Duration: ${activity.calculateDuration(_character.stats, difficultyCoefficient: _character.difficultyCoefficient).toStringAsFixed(1)}s | '
                            'Difficulty: ${activity.difficulty.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            'Rewards: ${_formatRewards(activity.rewards)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      trailing: ElevatedButton(
                        onPressed: meetsRequirements &&
                                !_activityManager.hasActiveActivity
                            ? () {
                                _activityManager.startActivity(activity);
                              }
                            : null,
                        child: Text(
                          meetsRequirements ? 'Start' : 'Locked',
                        ),
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRewards(Map<StatType, double> rewards) {
    return rewards.entries.map((e) {
      final statName = e.key.name.substring(0, 3).toUpperCase();
      return '+${e.value.toStringAsFixed(2)} $statName';
    }).join(', ');
  }
}
