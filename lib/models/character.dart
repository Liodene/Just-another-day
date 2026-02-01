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

  /// Creates a [CharacterStats] instance from a JSON map.
  factory CharacterStats.fromJson(Map<String, dynamic> json) {
    return CharacterStats(
      strength: (json['strength'] as num?)?.toDouble() ?? 1.0,
      intelligence: (json['intelligence'] as num?)?.toDouble() ?? 1.0,
      endurance: (json['endurance'] as num?)?.toDouble() ?? 1.0,
      charisma: (json['charisma'] as num?)?.toDouble() ?? 1.0,
      agility: (json['agility'] as num?)?.toDouble() ?? 1.0,
    );
  }

  /// Converts this [CharacterStats] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'strength': strength,
      'intelligence': intelligence,
      'endurance': endurance,
      'charisma': charisma,
      'agility': agility,
    };
  }

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
  /// Values are clamped to a minimum of 0.1 to prevent division by zero.
  void setStat(StatType type, double value) {
    final clampedValue = value.clamp(0.1, double.infinity);
    switch (type) {
      case StatType.strength:
        strength = clampedValue;
      case StatType.intelligence:
        intelligence = clampedValue;
      case StatType.endurance:
        endurance = clampedValue;
      case StatType.charisma:
        charisma = clampedValue;
      case StatType.agility:
        agility = clampedValue;
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
enum StatType { strength, intelligence, endurance, charisma, agility }

/// Represents a character in the game.
class Character {
  /// Creates a new [Character] with default stats.
  Character({
    required this.name,
    CharacterStats? stats,
    Map<String, int>? activityCompletions,
    Map<String, double>? savedActivityProgress,
    Map<String, int>? completionRecords,
  }) : stats = stats ?? CharacterStats(),
       _activityCompletions = activityCompletions ?? {},
       _savedActivityProgress = savedActivityProgress ?? {},
       _completionRecords = completionRecords ?? {};

  /// Creates a [Character] instance from a JSON map.
  factory Character.fromJson(Map<String, dynamic> json) {
    final completionsRaw = json['activityCompletions'];
    Map<String, int>? completions;
    if (completionsRaw != null && completionsRaw is Map) {
      completions = completionsRaw.map(
        (key, value) => MapEntry(key.toString(), (value as num).toInt()),
      );
    }
    final progressRaw = json['savedActivityProgress'];
    Map<String, double>? savedProgress;
    if (progressRaw != null && progressRaw is Map) {
      savedProgress = progressRaw.map(
        (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
      );
    }
    final recordsRaw = json['completionRecords'];
    Map<String, int>? records;
    if (recordsRaw != null && recordsRaw is Map) {
      records = recordsRaw.map(
        (key, value) => MapEntry(key.toString(), (value as num).toInt()),
      );
    }
    return Character(
      name: json['name'] as String? ?? 'Player',
      stats: json['stats'] != null
          ? CharacterStats.fromJson(json['stats'] as Map<String, dynamic>)
          : null,
      activityCompletions: completions,
      savedActivityProgress: savedProgress,
      completionRecords: records,
    );
  }

  /// Converts this [Character] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'stats': stats.toJson(),
      'activityCompletions': _activityCompletions,
      'savedActivityProgress': _savedActivityProgress,
      'completionRecords': _completionRecords,
    };
  }

  /// The character's name.
  final String name;

  /// The character's stats.
  final CharacterStats stats;

  /// Completion count per activity type (by activity ID).
  /// Each completion of an activity increases its difficulty by 1.10x.
  final Map<String, int> _activityCompletions;

  /// Saved partial progress for activities (by activity ID).
  /// Stores the progress percentage (0.0 to 1.0) when switching activities.
  final Map<String, double> _savedActivityProgress;

  /// Record of max completions reached in a single day per activity.
  /// Used to determine stat gains - only completions above the record give stats.
  final Map<String, int> _completionRecords;

  /// Gets the number of completions for a specific activity.
  int getCompletions(String activityId) {
    return _activityCompletions[activityId] ?? 0;
  }

  /// Increments the completion count for a specific activity.
  void addCompletion(String activityId) {
    _activityCompletions[activityId] =
        (_activityCompletions[activityId] ?? 0) + 1;
  }

  /// Resets all activity completions (difficulty resets at day start).
  void resetCompletions() {
    _activityCompletions.clear();
  }

  /// Saves partial progress for an activity.
  void saveActivityProgress(String activityId, double progress) {
    if (progress > 0 && progress < 1.0) {
      _savedActivityProgress[activityId] = progress;
    }
  }

  /// Gets saved partial progress for an activity (0.0 if none saved).
  double getSavedProgress(String activityId) {
    return _savedActivityProgress[activityId] ?? 0.0;
  }

  /// Clears saved progress for an activity (called when activity completes).
  void clearSavedProgress(String activityId) {
    _savedActivityProgress.remove(activityId);
  }

  /// Gets a copy of the saved activity progress map.
  Map<String, double> get savedActivityProgress =>
      Map<String, double>.from(_savedActivityProgress);

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

  /// Gets a copy of the activity completions map.
  Map<String, int> get activityCompletions =>
      Map<String, int>.from(_activityCompletions);

  /// Gets the completion record for a specific activity.
  /// This is the max completions reached in any single day.
  int getCompletionRecord(String activityId) {
    return _completionRecords[activityId] ?? 0;
  }

  /// Updates the completion record for an activity if the new value is higher.
  /// Returns the number of new levels gained (completions - oldRecord).
  int updateCompletionRecord(String activityId, int completions) {
    final oldRecord = _completionRecords[activityId] ?? 0;
    if (completions > oldRecord) {
      _completionRecords[activityId] = completions;
      return completions - oldRecord;
    }
    return 0;
  }

  /// Gets a copy of the completion records map.
  Map<String, int> get completionRecords =>
      Map<String, int>.from(_completionRecords);

  /// Restores state from another character (used when loading a save).
  /// Note: Does not restore the name field - the current character keeps its name.
  void restoreFrom(Character other) {
    stats.strength = other.stats.strength;
    stats.intelligence = other.stats.intelligence;
    stats.endurance = other.stats.endurance;
    stats.charisma = other.stats.charisma;
    stats.agility = other.stats.agility;
    _activityCompletions
      ..clear()
      ..addAll(other._activityCompletions);
    _savedActivityProgress
      ..clear()
      ..addAll(other._savedActivityProgress);
    _completionRecords
      ..clear()
      ..addAll(other._completionRecords);
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
