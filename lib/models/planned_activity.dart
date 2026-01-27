import 'activity.dart';

/// Defines how a planned activity's target is measured.
enum PlanTargetType {
  /// Target is a specific number of completions.
  completions,

  /// Target is a specific amount of in-game time.
  inGameTime,

  /// No specific target - runs indefinitely until cancelled.
  unlimited,
}

/// Represents a planned activity in the activity planner queue.
///
/// A planned activity specifies an activity to perform along with a target
/// that determines when the activity should be considered complete.
class PlannedActivity {
  /// Creates a new [PlannedActivity].
  PlannedActivity({
    required this.activity,
    required this.targetType,
    this.targetValue = 0,
    this.completedValue = 0,
  });

  /// Creates a [PlannedActivity] from a JSON map.
  factory PlannedActivity.fromJson(Map<String, dynamic> json) {
    final activityId = json['activityId'] as String;
    final activity = Activities.getById(activityId);
    if (activity == null) {
      throw ArgumentError('Unknown activity ID: $activityId');
    }
    return PlannedActivity(
      activity: activity,
      targetType: PlanTargetType.values.firstWhere(
        (t) => t.name == json['targetType'],
        orElse: () => PlanTargetType.completions,
      ),
      targetValue: (json['targetValue'] as num?)?.toDouble() ?? 0,
      completedValue: (json['completedValue'] as num?)?.toDouble() ?? 0,
    );
  }

  /// The activity to perform.
  final Activity activity;

  /// The type of target for this planned activity.
  final PlanTargetType targetType;

  /// The target value (number of completions or in-game seconds).
  /// Ignored for [PlanTargetType.unlimited].
  final double targetValue;

  /// The current completed value (completions done or time spent).
  double completedValue;

  /// Whether this planned activity's target has been reached.
  bool get isComplete {
    if (targetType == PlanTargetType.unlimited) {
      return false; // Never completes automatically
    }
    return completedValue >= targetValue;
  }

  /// Progress towards the target (0.0 to 1.0).
  /// Returns 0 for unlimited targets.
  double get progress {
    if (targetType == PlanTargetType.unlimited || targetValue <= 0) {
      return 0.0;
    }
    return (completedValue / targetValue).clamp(0.0, 1.0);
  }

  /// Remaining value until target is reached.
  /// Returns infinity for unlimited targets.
  double get remainingValue {
    if (targetType == PlanTargetType.unlimited) {
      return double.infinity;
    }
    return (targetValue - completedValue).clamp(0.0, targetValue);
  }

  /// Records a completion of the activity.
  void recordCompletion() {
    if (targetType == PlanTargetType.completions) {
      completedValue += 1;
    }
  }

  /// Records time spent on the activity.
  void recordTimeSpent(double inGameSeconds) {
    if (targetType == PlanTargetType.inGameTime) {
      completedValue += inGameSeconds;
    }
  }

  /// Creates a copy of this planned activity.
  PlannedActivity copyWith({
    Activity? activity,
    PlanTargetType? targetType,
    double? targetValue,
    double? completedValue,
  }) {
    return PlannedActivity(
      activity: activity ?? this.activity,
      targetType: targetType ?? this.targetType,
      targetValue: targetValue ?? this.targetValue,
      completedValue: completedValue ?? this.completedValue,
    );
  }

  /// Converts this [PlannedActivity] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'activityId': activity.id,
      'targetType': targetType.name,
      'targetValue': targetValue,
      'completedValue': completedValue,
    };
  }

  /// Returns a human-readable description of the target.
  String get targetDescription {
    switch (targetType) {
      case PlanTargetType.completions:
        final target = targetValue.toInt();
        final completed = completedValue.toInt();
        return '$completed / $target completions';
      case PlanTargetType.inGameTime:
        return '${_formatTime(completedValue)} / ${_formatTime(targetValue)}';
      case PlanTargetType.unlimited:
        return 'Unlimited';
    }
  }

  /// Formats in-game seconds as a human-readable time string.
  static String _formatTime(double seconds) {
    final totalSeconds = seconds.toInt();
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final secs = totalSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }

  @override
  String toString() =>
      'PlannedActivity(${activity.name}, $targetType, $targetDescription)';
}
