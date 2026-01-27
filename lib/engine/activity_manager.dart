import 'package:flutter/foundation.dart';

import '../models/activity.dart';
import '../models/character.dart';
import '../models/game_time.dart';
import 'game_loop.dart';

/// Callback type for when an activity completes.
typedef ActivityCompletedCallback = void Function(
  Activity activity,
  Map<StatType, double> rewards,
);

/// Callback type for when activity progress changes.
typedef ActivityProgressCallback = void Function(ActivityProgress? progress);

/// Manages activity progression and integrates with the game loop.
///
/// This class handles:
/// - Starting and stopping activities
/// - Tracking activity progress
/// - Applying stat rewards on completion
/// - Auto-repeating activities
/// - Tracking in-game time and real time played
class ActivityManager extends ChangeNotifier {
  /// Creates a new [ActivityManager].
  ActivityManager({
    required this.character,
    required GameLoop gameLoop,
    GameTime? gameTime,
  })  : _gameLoop = gameLoop,
        gameTime = gameTime ?? GameTime() {
    _removeCallback = _gameLoop.addCallback(_onGameLoopTick);
  }

  /// The character performing activities.
  final Character character;

  /// The in-game clock and time tracker.
  final GameTime gameTime;

  final GameLoop _gameLoop;
  late final VoidCallback _removeCallback;

  ActivityProgress? _currentProgress;
  bool _autoRepeat = false;
  ActivityCompletedCallback? _onActivityCompleted;
  ActivityProgressCallback? _onProgressChanged;

  /// The current activity progress, or null if no activity is running.
  ActivityProgress? get currentProgress => _currentProgress;

  /// The current activity, or null if none.
  Activity? get currentActivity => _currentProgress?.activity;

  /// Whether there is an active activity.
  bool get hasActiveActivity => _currentProgress != null;

  /// Whether auto-repeat is enabled.
  bool get autoRepeat => _autoRepeat;

  /// Sets whether activities should auto-repeat on completion.
  set autoRepeat(bool value) {
    _autoRepeat = value;
    notifyListeners();
  }

  /// Sets a callback for when an activity completes.
  set onActivityCompleted(ActivityCompletedCallback? callback) {
    _onActivityCompleted = callback;
  }

  /// Sets a callback for when progress changes.
  set onProgressChanged(ActivityProgressCallback? callback) {
    _onProgressChanged = callback;
  }

  /// Starts an activity.
  ///
  /// Returns true if the activity was started successfully.
  /// Returns false if requirements are not met or another activity is running
  /// (unless force is true).
  ///
  /// When switching activities, partial progress is automatically saved and
  /// will be restored when returning to the activity.
  bool startActivity(Activity activity, {bool force = false}) {
    // Check if we can start (unless forcing)
    if (!force && hasActiveActivity) {
      return false;
    }

    // Check requirements
    if (!activity.meetsRequirements(character.stats)) {
      return false;
    }

    // Save partial progress of current activity before switching
    if (_currentProgress != null &&
        _currentProgress!.activity.id != activity.id) {
      _saveCurrentProgress();
    }

    // Calculate duration based on character stats and activity-specific
    // difficulty coefficient
    final duration = activity.calculateDuration(
      character.stats,
      difficultyCoefficient: character.getDifficultyCoefficient(activity.id),
    );

    // Check for saved progress and restore it
    final savedProgress = character.getSavedProgress(activity.id);
    final elapsedTime = savedProgress * duration;

    _currentProgress = ActivityProgress(
      activity: activity,
      totalDuration: duration,
      elapsedTime: elapsedTime,
    );

    // Clear saved progress since we've restored it
    if (savedProgress > 0) {
      character.clearSavedProgress(activity.id);
    }

    _onProgressChanged?.call(_currentProgress);
    notifyListeners();
    return true;
  }

  /// Saves the current activity's partial progress to the character.
  void _saveCurrentProgress() {
    if (_currentProgress != null && !_currentProgress!.isComplete) {
      character.saveActivityProgress(
        _currentProgress!.activity.id,
        _currentProgress!.progress,
      );
    }
  }

  /// Stops the current activity.
  ///
  /// If [grantPartialRewards] is true, grants a portion of the rewards
  /// based on progress.
  /// If [saveProgress] is true (default), saves the partial progress so it
  /// can be resumed later.
  void stopActivity({
    bool grantPartialRewards = false,
    bool saveProgress = true,
  }) {
    if (_currentProgress == null) return;

    if (grantPartialRewards && _currentProgress!.progress > 0) {
      _applyRewards(_currentProgress!.activity, _currentProgress!.progress);
    }

    // Save partial progress before stopping (unless granting rewards)
    if (saveProgress && !grantPartialRewards) {
      _saveCurrentProgress();
    }

    _currentProgress = null;
    _onProgressChanged?.call(null);
    notifyListeners();
  }

  /// Gets all activities available to the character (meeting requirements).
  List<Activity> getAvailableActivities() {
    return Activities.all
        .where((a) => a.meetsRequirements(character.stats))
        .toList();
  }

  /// Gets all activities, including those with unmet requirements.
  List<Activity> getAllActivities() {
    return Activities.all;
  }

  void _onGameLoopTick(double deltaTimeMs) {
    // Update game time (always, even without active activity)
    gameTime.update(deltaTimeMs);

    if (_currentProgress == null) {
      notifyListeners();
      return;
    }

    // Convert milliseconds to seconds for activity progress
    final deltaTimeSec = deltaTimeMs / 1000.0;
    final justCompleted = _currentProgress!.update(deltaTimeSec);
    _onProgressChanged?.call(_currentProgress);

    if (justCompleted) {
      _onActivityComplete();
    }

    notifyListeners();
  }

  void _onActivityComplete() {
    final activity = _currentProgress!.activity;

    // Apply full rewards
    _applyRewards(activity, 1.0);

    // Increment this activity's completion count (increases its difficulty)
    character.addCompletion(activity.id);

    // Clear any saved progress since activity completed
    character.clearSavedProgress(activity.id);

    // Notify listeners
    _onActivityCompleted?.call(activity, activity.rewards);

    // Handle auto-repeat
    if (_autoRepeat) {
      // Restart the same activity with new difficulty coefficient
      final duration = activity.calculateDuration(
        character.stats,
        difficultyCoefficient: character.getDifficultyCoefficient(activity.id),
      );
      _currentProgress = ActivityProgress(
        activity: activity,
        totalDuration: duration,
      );
    } else {
      _currentProgress = null;
    }

    _onProgressChanged?.call(_currentProgress);
  }

  void _applyRewards(Activity activity, double multiplier) {
    for (final entry in activity.rewards.entries) {
      final amount = entry.value * multiplier;
      character.stats.addToStat(entry.key, amount);
    }
  }

  /// Disposes of the activity manager and cleans up resources.
  @override
  void dispose() {
    _removeCallback();
    super.dispose();
  }
}
