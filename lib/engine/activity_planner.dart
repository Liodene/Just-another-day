import 'package:flutter/foundation.dart';

import '../models/activity.dart';
import '../models/planned_activity.dart';

/// Manages a queue of planned activities.
///
/// The planner allows users to create a list of activities to perform
/// in sequence, each with a target (completions, time, or unlimited).
/// When an activity's target is reached, the planner moves to the next one.
class ActivityPlanner extends ChangeNotifier {
  /// Creates a new [ActivityPlanner].
  ActivityPlanner();

  final List<PlannedActivity> _queue = [];

  /// The planned activities queue (read-only view).
  List<PlannedActivity> get queue => List.unmodifiable(_queue);

  /// Whether there are any planned activities.
  bool get hasPlannedActivities => _queue.isNotEmpty;

  /// The current (first) planned activity, or null if queue is empty.
  PlannedActivity? get currentPlanned => _queue.isEmpty ? null : _queue.first;

  /// Whether the current planned activity is unlimited.
  bool get isCurrentUnlimited =>
      currentPlanned?.targetType == PlanTargetType.unlimited;

  /// Total estimated in-game time for all planned activities.
  /// Returns a Duration with microseconds set to -1 if any activity is unlimited
  /// (checked via duration.isNegative).
  Duration estimateTotalTime(
    Duration Function(Activity activity) durationCalculator,
  ) {
    var total = Duration.zero;
    for (final planned in _queue) {
      if (planned.targetType == PlanTargetType.unlimited) {
        return const Duration(microseconds: -1); // Represents infinity
      }
      final duration = durationCalculator(planned.activity);
      switch (planned.targetType) {
        case PlanTargetType.completions:
          // Remaining completions times duration per completion
          final remaining = planned.targetValue - planned.completedValue;
          total += duration * remaining;
        case PlanTargetType.inGameTime:
          // Remaining time (targetValue and completedValue are in seconds)
          final remainingSeconds = planned.targetValue - planned.completedValue;
          total += Duration(seconds: remainingSeconds.toInt());
        case PlanTargetType.unlimited:
          // Already handled above
          break;
      }
    }
    return total;
  }

  /// Adds a planned activity to the queue.
  ///
  /// Returns false if:
  /// - The queue already ends with an unlimited activity
  /// - The activity would create an invalid state
  bool addPlannedActivity(PlannedActivity planned) {
    // Cannot add after an unlimited activity
    if (_queue.isNotEmpty &&
        _queue.last.targetType == PlanTargetType.unlimited) {
      return false;
    }

    _queue.add(planned);
    notifyListeners();
    return true;
  }

  /// Removes a planned activity at the given index.
  ///
  /// Returns the removed activity, or null if index is invalid.
  PlannedActivity? removeAt(int index) {
    if (index < 0 || index >= _queue.length) return null;

    final removed = _queue.removeAt(index);
    notifyListeners();
    return removed;
  }

  /// Clears all planned activities.
  void clearPlan() {
    _queue.clear();
    notifyListeners();
  }

  /// Records a completion for the current planned activity.
  ///
  /// If the current activity's target is reached, moves to the next one.
  /// Returns the activity that completed its plan target, or null if none.
  PlannedActivity? recordCompletion() {
    if (_queue.isEmpty) return null;

    final current = _queue.first;
    current.recordCompletion();

    if (current.isComplete) {
      _queue.removeAt(0);
      notifyListeners();
      return current;
    }

    notifyListeners();
    return null;
  }

  /// Records time spent on the current planned activity.
  ///
  /// If the current activity's target is reached, moves to the next one.
  /// Returns the activity that completed its plan target, or null if none.
  PlannedActivity? recordTimeSpent(Duration inGameTime) {
    if (_queue.isEmpty) return null;

    final current = _queue.first;
    current.recordTimeSpent(inGameTime);

    if (current.isComplete) {
      _queue.removeAt(0);
      notifyListeners();
      return current;
    }

    notifyListeners();
    return null;
  }

  /// Moves a planned activity from one position to another.
  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _queue.length) return;
    if (newIndex < 0 || newIndex > _queue.length) return;

    // Check if moving would place something after an unlimited activity
    final movedItem = _queue[oldIndex];
    final adjustedNewIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;

    // If the last item is unlimited and we're trying to add after it
    if (adjustedNewIndex == _queue.length - 1 &&
        _queue.isNotEmpty &&
        _queue.last.targetType == PlanTargetType.unlimited &&
        movedItem.targetType != PlanTargetType.unlimited) {
      return;
    }

    final item = _queue.removeAt(oldIndex);
    _queue.insert(adjustedNewIndex, item);
    notifyListeners();
  }

  /// Whether an activity can be added to the queue.
  bool canAddActivity() {
    if (_queue.isEmpty) return true;
    // Cannot add after an unlimited activity
    return _queue.last.targetType != PlanTargetType.unlimited;
  }

  /// Converts the planner state to JSON.
  List<Map<String, dynamic>> toJson() {
    return _queue.map((p) => p.toJson()).toList();
  }

  /// Restores the planner state from JSON.
  void restoreFromJson(List<dynamic> json) {
    _queue.clear();
    for (final item in json) {
      try {
        final planned = PlannedActivity.fromJson(item as Map<String, dynamic>);
        _queue.add(planned);
      } catch (e) {
        // Skip invalid entries
        debugPrint('Failed to restore planned activity: $e');
      }
    }
    notifyListeners();
  }
}
