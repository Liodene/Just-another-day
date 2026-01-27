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
/// - Managing an activity plan (queue of activities to perform)
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

  /// The activity plan (queue of activities to perform in order).
  final List<Activity> _activityPlan = [];

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

  /// Gets a read-only view of the activity plan.
  List<Activity> get activityPlan => List.unmodifiable(_activityPlan);

  /// Whether the activity plan has any activities.
  bool get hasPlan => _activityPlan.isNotEmpty;

  /// Adds an activity to the end of the plan.
  ///
  /// If no activity is currently running and this is the first activity
  /// in the plan, it will be started automatically.
  void addToPlan(Activity activity) {
    _activityPlan.add(activity);
    notifyListeners();

    // If nothing is running and this is the only activity, start it
    if (!hasActiveActivity && _activityPlan.length == 1) {
      _startNextFromPlan();
    }
  }

  /// Inserts an activity at a specific position in the plan.
  void insertIntoPlan(int index, Activity activity) {
    final clampedIndex = index.clamp(0, _activityPlan.length);
    _activityPlan.insert(clampedIndex, activity);
    notifyListeners();

    // If nothing is running and inserted at position 0, start it
    if (!hasActiveActivity && clampedIndex == 0) {
      _startNextFromPlan();
    }
  }

  /// Removes an activity from the plan by index.
  ///
  /// If the removed activity is the current activity (index 0 and running),
  /// the current activity will be cancelled, its progress saved, and the
  /// next activity in the plan will be started.
  ///
  /// Returns the removed activity, or null if index is out of bounds.
  Activity? removeFromPlan(int index) {
    if (index < 0 || index >= _activityPlan.length) {
      return null;
    }

    final removedActivity = _activityPlan[index];

    // Check if we're removing the current activity
    final isRemovingCurrentActivity = index == 0 &&
        hasActiveActivity &&
        currentActivity?.id == removedActivity.id;

    if (isRemovingCurrentActivity) {
      // Save progress and stop the current activity
      stopActivity(saveProgress: true);
    }

    _activityPlan.removeAt(index);
    notifyListeners();

    // If we removed the current activity and there are more in the plan,
    // start the next one
    if (isRemovingCurrentActivity && _activityPlan.isNotEmpty) {
      _startNextFromPlan();
    }

    return removedActivity;
  }

  /// Removes a specific activity from the plan.
  ///
  /// If the activity appears multiple times, only the first occurrence
  /// is removed. If the removed activity is currently running, its progress
  /// will be saved and the next activity will be started.
  ///
  /// Returns true if the activity was found and removed.
  bool removeActivityFromPlan(Activity activity) {
    final index = _activityPlan.indexWhere((a) => a.id == activity.id);
    if (index == -1) {
      return false;
    }
    removeFromPlan(index);
    return true;
  }

  /// Clears all activities from the plan.
  ///
  /// If an activity is currently running, it will be stopped and its
  /// progress saved.
  void clearPlan() {
    if (hasActiveActivity) {
      stopActivity(saveProgress: true);
    }
    _activityPlan.clear();
    notifyListeners();
  }

  /// Reorders an activity in the plan from one position to another.
  void reorderPlan(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _activityPlan.length) return;
    if (newIndex < 0 || newIndex > _activityPlan.length) return;

    // If moving the current activity (index 0) and it's running,
    // we need to handle it specially
    final isMovingCurrentActivity = oldIndex == 0 && hasActiveActivity;

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final activity = _activityPlan.removeAt(oldIndex);
    _activityPlan.insert(newIndex, activity);

    // If we moved the current activity away from position 0,
    // save progress and start the new first activity
    if (isMovingCurrentActivity && newIndex != 0 && _activityPlan.isNotEmpty) {
      stopActivity(saveProgress: true);
      _startNextFromPlan();
    }

    notifyListeners();
  }

  /// Starts the next activity from the plan.
  void _startNextFromPlan() {
    if (_activityPlan.isEmpty) return;

    final nextActivity = _activityPlan.first;
    if (nextActivity.meetsRequirements(character.stats)) {
      startActivity(nextActivity, force: true);
    } else {
      // If requirements not met, remove and try next
      _activityPlan.removeAt(0);
      notifyListeners();
      _startNextFromPlan();
    }
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

    // Remove completed activity from plan (if it's at the front)
    if (_activityPlan.isNotEmpty && _activityPlan.first.id == activity.id) {
      _activityPlan.removeAt(0);
    }

    // Clear current progress first
    _currentProgress = null;

    // Determine next activity: plan takes priority, then auto-repeat
    if (_activityPlan.isNotEmpty) {
      // Start next activity from plan
      _startNextFromPlan();
    } else if (_autoRepeat) {
      // No plan, but auto-repeat is enabled - restart same activity
      final duration = activity.calculateDuration(
        character.stats,
        difficultyCoefficient: character.getDifficultyCoefficient(activity.id),
      );
      _currentProgress = ActivityProgress(
        activity: activity,
        totalDuration: duration,
      );
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
