import 'character.dart';

/// Represents an activity that a character can perform.
///
/// Activities have a base duration and difficulty, and grant stat rewards
/// upon completion. The actual duration is affected by the character's
/// relevant stats.
class Activity {
  /// Creates a new [Activity].
  const Activity({
    required this.id,
    required this.name,
    required this.description,
    required this.baseDuration,
    required this.difficulty,
    required this.primaryStat,
    required this.rewards,
    this.requirements,
  });

  /// Unique identifier for the activity.
  final String id;

  /// Display name of the activity.
  final String name;

  /// Description of what the activity involves.
  final String description;

  /// Base duration to complete the activity.
  final Duration baseDuration;

  /// Difficulty level (1-100). Higher difficulty means slower progress.
  final double difficulty;

  /// The primary stat that affects completion speed.
  final StatType primaryStat;

  /// Stat rewards granted upon completion.
  final Map<StatType, double> rewards;

  /// Minimum stat requirements to attempt this activity.
  /// If null, no requirements are needed.
  final Map<StatType, double>? requirements;

  /// Calculates the actual duration based on character stats and level.
  ///
  /// Higher stats reduce the duration, but higher levels increase it.
  /// The formula is:
  /// effectiveDifficulty = difficulty * difficultyCoefficient
  /// actualDuration = baseDuration * (effectiveDifficulty / primaryStatValue)
  ///
  /// The [difficultyCoefficient] is 1.10 per level (1.10^(level-1)).
  /// The duration is clamped to be at least 10% of the base duration.
  Duration calculateDuration(
    CharacterStats stats, {
    double difficultyCoefficient = 1.0,
  }) {
    final statValue = stats.getStat(primaryStat);
    final effectiveDifficulty = difficulty * difficultyCoefficient;
    final multiplier = (effectiveDifficulty / statValue).clamp(0.1, 10.0);
    final seconds = (baseDuration.inMicroseconds * multiplier).round();
    return Duration(microseconds: seconds);
  }

  /// Checks if the character meets the requirements for this activity.
  bool meetsRequirements(CharacterStats stats) {
    if (requirements == null) return true;

    for (final entry in requirements!.entries) {
      if (stats.getStat(entry.key) < entry.value) {
        return false;
      }
    }
    return true;
  }

  @override
  String toString() =>
      'Activity($name, duration: ${baseDuration.inSeconds}s, difficulty: $difficulty)';
}

/// Represents the current progress of an activity.
class ActivityProgress {
  /// Creates a new [ActivityProgress].
  ActivityProgress({
    required this.activity,
    required this.totalDuration,
    Duration? elapsedTime,
  }) : elapsedTime = elapsedTime ?? Duration.zero;

  /// The activity being performed.
  final Activity activity;

  /// Total duration needed to complete (calculated from character stats).
  final Duration totalDuration;

  /// Time elapsed so far.
  Duration elapsedTime;

  /// Progress percentage (0.0 to 1.0).
  double get progress =>
      (elapsedTime.inMicroseconds / totalDuration.inMicroseconds)
          .clamp(0.0, 1.0);

  /// Whether the activity is complete.
  bool get isComplete => elapsedTime >= totalDuration;

  /// Remaining time.
  Duration get remainingTime =>
      totalDuration - elapsedTime < Duration.zero
          ? Duration.zero
          : totalDuration - elapsedTime;

  /// Updates the progress by adding delta time.
  ///
  /// Returns true if the activity just completed.
  bool update(Duration deltaTime) {
    if (isComplete) return false;

    elapsedTime += deltaTime;
    return isComplete;
  }

  @override
  String toString() =>
      'ActivityProgress(${activity.name}, ${(progress * 100).toStringAsFixed(1)}%)';
}

/// Pre-defined activities for the game.
class Activities {
  Activities._();

  static const working = Activity(
    id: 'working',
    name: 'Working',
    description: 'Work a job to earn experience and improve your endurance.',
    baseDuration: Duration(seconds: 10),
    difficulty: 0.5,
    primaryStat: StatType.endurance,
    rewards: {StatType.endurance: 0.1, StatType.charisma: 0.05},
  );

  static const studying = Activity(
    id: 'studying',
    name: 'Studying',
    description: 'Study to improve your intelligence.',
    baseDuration: Duration(seconds: 15),
    difficulty: 0.8,
    primaryStat: StatType.intelligence,
    rewards: {StatType.intelligence: 0.15},
  );

  static const exercising = Activity(
    id: 'exercising',
    name: 'Exercising',
    description: 'Work out to improve your strength and agility.',
    baseDuration: Duration(seconds: 8),
    difficulty: 0.6,
    primaryStat: StatType.strength,
    rewards: {
      StatType.strength: 0.1,
      StatType.agility: 0.05,
      StatType.endurance: 0.05,
    },
  );

  static const sparring = Activity(
    id: 'sparring',
    name: 'Sparring',
    description: 'Practice combat to improve fighting abilities.',
    baseDuration: Duration(seconds: 12),
    difficulty: 1.0,
    primaryStat: StatType.agility,
    requirements: {StatType.strength: 3.0},
    rewards: {StatType.strength: 0.1, StatType.agility: 0.15},
  );

  static const socializing = Activity(
    id: 'socializing',
    name: 'Socializing',
    description: 'Spend time with others to improve your charisma.',
    baseDuration: Duration(seconds: 5),
    difficulty: 0.3,
    primaryStat: StatType.charisma,
    rewards: {StatType.charisma: 0.1},
  );

  /// All available activities.
  static const List<Activity> all = [
    working,
    studying,
    exercising,
    sparring,
    socializing,
  ];

  /// Gets an activity by its ID, or null if not found.
  static Activity? getById(String id) {
    for (final activity in all) {
      if (activity.id == id) return activity;
    }
    return null;
  }
}
