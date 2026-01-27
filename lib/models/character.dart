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
  }) : stats = stats ?? CharacterStats();

  /// The character's name.
  final String name;

  /// The character's stats.
  final CharacterStats stats;

  @override
  String toString() => 'Character($name, $stats)';
}
