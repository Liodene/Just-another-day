/// Represents the stats of a character in the game.
///
/// Each stat affects how quickly the character can complete activities
/// and may unlock certain activities based on minimum requirements.
class CharacterStats {
  /// Creates a new [CharacterStats] instance with the given values.
  CharacterStats({
    this.strength = 1.0,
    this.intelligence = 1.0,
    this.endurance = 1.0,
    this.charisma = 1.0,
    this.agility = 1.0,
  });

  /// Physical power - affects combat and physical labor activities.
  double strength;

  /// Mental capacity - affects education and research activities.
  double intelligence;

  /// Stamina - affects how long activities can be sustained and overall speed.
  double endurance;

  /// Social skills - affects social and business activities.
  double charisma;

  /// Speed and reflexes - affects sports and combat activities.
  double agility;

  /// Creates a copy of this stats instance.
  CharacterStats copyWith({
    double? strength,
    double? intelligence,
    double? endurance,
    double? charisma,
    double? agility,
  }) {
    return CharacterStats(
      strength: strength ?? this.strength,
      intelligence: intelligence ?? this.intelligence,
      endurance: endurance ?? this.endurance,
      charisma: charisma ?? this.charisma,
      agility: agility ?? this.agility,
    );
  }

  /// Gets the total of all stats.
  double get total => strength + intelligence + endurance + charisma + agility;

  /// Gets a stat value by its type.
  double getStat(StatType type) {
    switch (type) {
      case StatType.strength:
        return strength;
      case StatType.intelligence:
        return intelligence;
      case StatType.endurance:
        return endurance;
      case StatType.charisma:
        return charisma;
      case StatType.agility:
        return agility;
    }
  }

  /// Sets a stat value by its type.
  void setStat(StatType type, double value) {
    switch (type) {
      case StatType.strength:
        strength = value;
      case StatType.intelligence:
        intelligence = value;
      case StatType.endurance:
        endurance = value;
      case StatType.charisma:
        charisma = value;
      case StatType.agility:
        agility = value;
    }
  }

  /// Adds to a stat value by its type.
  void addToStat(StatType type, double amount) {
    setStat(type, getStat(type) + amount);
  }

  @override
  String toString() {
    return 'CharacterStats(str: $strength, int: $intelligence, end: $endurance, '
        'cha: $charisma, agi: $agility)';
  }
}

/// The types of character stats available.
enum StatType {
  strength,
  intelligence,
  endurance,
  charisma,
  agility,
}

/// Represents a character in the game.
class Character {
  /// Creates a new [Character] with default stats.
  Character({
    required this.name,
    CharacterStats? stats,
    Map<String, int>? activityCompletions,
  })  : stats = stats ?? CharacterStats(),
        _activityCompletions = activityCompletions ?? {};

  /// The character's name.
  final String name;

  /// The character's stats.
  final CharacterStats stats;

  /// Completion count per activity type (by activity ID).
  /// Each completion of an activity increases its difficulty by 1.10x.
  final Map<String, int> _activityCompletions;

  /// Gets the number of completions for a specific activity.
  int getCompletions(String activityId) {
    return _activityCompletions[activityId] ?? 0;
  }

  /// Increments the completion count for a specific activity.
  void addCompletion(String activityId) {
    _activityCompletions[activityId] =
        (_activityCompletions[activityId] ?? 0) + 1;
  }

  /// Gets the difficulty coefficient for a specific activity.
  /// Formula: 1.10 ^ completions
  /// 0 completions = 1.0x, 1 completion = 1.1x, 2 completions = 1.21x, etc.
  double getDifficultyCoefficient(String activityId) {
    final completions = getCompletions(activityId);
    if (completions <= 0) return 1.0;
    return _pow(1.10, completions);
  }

  /// Gets total completions across all activities.
  int get totalCompletions {
    return _activityCompletions.values.fold(0, (sum, count) => sum + count);
  }

  /// Simple power function for double base and int exponent.
  static double _pow(double base, int exponent) {
    var result = 1.0;
    for (var i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }

  @override
  String toString() =>
      'Character($name, totalCompletions: $totalCompletions, $stats)';
}
