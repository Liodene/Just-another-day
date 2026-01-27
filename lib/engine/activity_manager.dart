import 'package:flutter/foundation.dart';

import '../models/activity.dart';
import '../models/character.dart';
import '../models/game_time.dart';
import '../models/planned_activity.dart';
import 'activity_planner.dart';
import 'game_loop.dart';

/// Callback type for when an activity completes.
typedef ActivityCompletedCallback =
    void Function(Activity activity, Map<StatType, double> rewards);

/// Callback type for when activity progress changes.
typedef ActivityProgressCallback = void Function(ActivityProgress? progress);

/// Callback type for when a planned activity completes its target.
typedef PlannedActivityCompletedCallback =
    void Function(PlannedActivity planned);

/// Manages activity progression and integrates with the game loop.
///
/// This class handles:
/// - Starting and stopping activities
/// - Tracking activity progress
/// - Applying stat rewards on completion
/// - Auto-repeating activities
/// - Tracking in-game time and real time played
/// - Activity planning and queue management
class ActivityManager extends ChangeNotifier {
  /// Creates a new [ActivityManager].
  ActivityManager({
    required this.character,
    required GameLoop gameLoop,
    GameTime? gameTime,
    ActivityPlanner? planner,
  }) : _gameLoop = gameLoop,
       gameTime = gameTime ?? GameTime(),
       _planner = planner ?? ActivityPlanner() {
    _removeCallback = _gameLoop.addCallback(_onGameLoopTick);
    _planner.addListener(_onPlannerChanged);
  }

  /// The character performing activities.
  final Character character;

  /// The in-game clock and time tracker.
  final GameTime gameTime;

  final GameLoop _gameLoop;
  final ActivityPlanner _planner;
  late final VoidCallback _removeCallback;

  ActivityProgress? _currentProgress;
  bool _autoRepeat = false;
  ActivityCompletedCallback? _onActivityCompleted;
  ActivityProgressCallback? _onProgressChanged;
  PlannedActivityCompletedCallback? _onPlannedActivityCompleted;

  /// The activity planner for managing the activity queue.
  ActivityPlanner get planner => _planner;

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

  /// Sets a callback for when a planned activity completes its target.
  set onPlannedActivityCompleted(PlannedActivityCompletedCallback? callback) {
    _onPlannedActivityCompleted = callback;
  }

  void _onPlannerChanged() {
    notifyListeners();
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
    // Only update game time when there's an active activity
    if (_currentProgress != null) {
      gameTime.update(deltaTimeMs);

      // Convert milliseconds to seconds for activity progress
      final deltaTimeSec = deltaTimeMs / 1000.0;

      // Track time for planned activity (in-game time, not real time)
      final inGameDeltaSec = deltaTimeSec * gameTime.timeMultiplier;
      final completedPlan = _planner.recordTimeSpent(inGameDeltaSec);
      if (completedPlan != null) {
        _onPlannedActivityCompleted?.call(completedPlan);
        _advanceToNextPlannedActivity();
      }

      final justCompleted = _currentProgress!.update(deltaTimeSec);
      _onProgressChanged?.call(_currentProgress);

      if (justCompleted) {
        _onActivityComplete();
      }
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

    // Record completion for planner (for completion-based targets)
    final completedPlan = _planner.recordCompletion();
    if (completedPlan != null) {
      _onPlannedActivityCompleted?.call(completedPlan);
      _advanceToNextPlannedActivity();
      return;
    }

    // Handle auto-repeat or continue planned activity
    if (_planner.hasPlannedActivities || _autoRepeat) {
      // Check if we should continue with the planned activity
      final planned = _planner.currentPlanned;
      if (planned != null && planned.activity.id == activity.id) {
        // Continue with the same activity
        final duration = activity.calculateDuration(
          character.stats,
          difficultyCoefficient: character.getDifficultyCoefficient(
            activity.id,
          ),
        );
        _currentProgress = ActivityProgress(
          activity: activity,
          totalDuration: duration,
        );
      } else if (_autoRepeat && !_planner.hasPlannedActivities) {
        // Auto-repeat without planner
        final duration = activity.calculateDuration(
          character.stats,
          difficultyCoefficient: character.getDifficultyCoefficient(
            activity.id,
          ),
        );
        _currentProgress = ActivityProgress(
          activity: activity,
          totalDuration: duration,
        );
      } else {
        _currentProgress = null;
      }
    } else {
      _currentProgress = null;
    }

    _onProgressChanged?.call(_currentProgress);
  }

  /// Advances to the next planned activity in the queue.
  void _advanceToNextPlannedActivity() {
    final next = _planner.currentPlanned;
    if (next != null) {
      // Start the next planned activity
      startActivity(next.activity, force: true);
    } else {
      // No more planned activities
      _currentProgress = null;
      _onProgressChanged?.call(null);
    }
  }

  /// Starts executing the activity plan from the beginning.
  ///
  /// Returns true if the plan was started successfully.
  bool startPlan() {
    if (!_planner.hasPlannedActivities) return false;

    final first = _planner.currentPlanned!;
    return startActivity(first.activity, force: true);
  }

  /// Cancels the current plan and stops any active activity.
  void cancelPlan() {
    _planner.clearPlan();
    stopActivity(saveProgress: true);
  }

  /// Removes a planned activity at the given index.
  ///
  /// If removing the current (first) activity while it's running:
  /// - Stops the current activity and saves progress
  /// - Starts the next planned activity (if any)
  ///
  /// Returns the removed activity, or null if index is invalid.
  PlannedActivity? removePlannedActivity(int index) {
    if (index < 0 || index >= _planner.queue.length) return null;

    final isRemovingCurrent = index == 0;
    final wasRunning =
        hasActiveActivity &&
        isRemovingCurrent &&
        currentActivity?.id == _planner.currentPlanned?.activity.id;

    // Remove from planner
    final removed = _planner.removeAt(index);

    // If we removed the currently running activity, handle the transition
    if (wasRunning && removed != null) {
      // Stop current activity and save progress
      stopActivity(saveProgress: true);

      // Start next planned activity if there is one
      final next = _planner.currentPlanned;
      if (next != null) {
        startActivity(next.activity, force: true);
      }
    }

    return removed;
  }

  /// Calculates the duration for an activity based on current character stats.
  double calculateActivityDuration(Activity activity) {
    return activity.calculateDuration(
      character.stats,
      difficultyCoefficient: character.getDifficultyCoefficient(activity.id),
    );
  }

  /// Estimates the total in-game time for the current plan.
  ///
  /// This takes into account:
  /// - Difficulty increasing with each completion (1.10x per completion)
  /// - Stats improving from activity rewards after each completion
  double estimatePlanTime() {
    if (!_planner.hasPlannedActivities) return 0.0;

    // Create simulated stats (copy of current stats)
    final simStats = character.stats.copyWith();

    // Track simulated completions per activity
    final simCompletions = Map<String, int>.from(character.activityCompletions);

    var totalTime = 0.0;

    for (final planned in _planner.queue) {
      if (planned.targetType == PlanTargetType.unlimited) {
        return double.infinity;
      }

      final activity = planned.activity;
      final activityId = activity.id;

      switch (planned.targetType) {
        case PlanTargetType.completions:
          // Calculate time for each remaining completion
          final remaining = (planned.targetValue - planned.completedValue)
              .toInt();
          for (var i = 0; i < remaining; i++) {
            // Calculate duration with current simulated state
            final coefficient = _calculateCoefficient(
              simCompletions[activityId] ?? 0,
            );
            final duration = activity.calculateDuration(
              simStats,
              difficultyCoefficient: coefficient,
            );
            totalTime += duration;

            // Simulate completion: update stats and difficulty
            _applySimulatedRewards(simStats, activity.rewards);
            simCompletions[activityId] = (simCompletions[activityId] ?? 0) + 1;
          }

        case PlanTargetType.inGameTime:
          // For time-based targets, estimate how many completions will occur
          // and account for stats evolution during that time
          var remainingTime = planned.targetValue - planned.completedValue;
          while (remainingTime > 0) {
            final coefficient = _calculateCoefficient(
              simCompletions[activityId] ?? 0,
            );
            final duration = activity.calculateDuration(
              simStats,
              difficultyCoefficient: coefficient,
            );

            if (duration >= remainingTime) {
              // Partial completion - just add remaining time
              totalTime += remainingTime;
              break;
            }

            // Full completion within the time budget
            totalTime += duration;
            remainingTime -= duration;

            // Simulate completion: update stats and difficulty
            _applySimulatedRewards(simStats, activity.rewards);
            simCompletions[activityId] = (simCompletions[activityId] ?? 0) + 1;
          }

        case PlanTargetType.unlimited:
          // Already handled above
          break;
      }
    }

    return totalTime;
  }

  /// Calculates difficulty coefficient for a given number of completions.
  static double _calculateCoefficient(int completions) {
    if (completions <= 0) return 1.0;
    var result = 1.0;
    for (var i = 0; i < completions; i++) {
      result *= 1.10;
    }
    return result;
  }

  /// Applies rewards to simulated stats.
  void _applySimulatedRewards(
    CharacterStats stats,
    Map<StatType, double> rewards,
  ) {
    for (final entry in rewards.entries) {
      stats.addToStat(entry.key, entry.value);
    }
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
    _planner.removeListener(_onPlannerChanged);
    _planner.dispose();
    super.dispose();
  }
}
