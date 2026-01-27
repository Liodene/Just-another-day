import 'package:flutter_test/flutter_test.dart';
import 'package:just_another_day/models/character.dart';

void main() {
  group('CharacterStats', () {
    test('should have default values of 1.0', () {
      final stats = CharacterStats();

      expect(stats.strength, equals(1.0));
      expect(stats.intelligence, equals(1.0));
      expect(stats.endurance, equals(1.0));
      expect(stats.charisma, equals(1.0));
      expect(stats.agility, equals(1.0));
    });

    test('should accept custom initial values', () {
      final stats = CharacterStats(
        strength: 5.0,
        intelligence: 10.0,
        endurance: 3.0,
        charisma: 7.0,
        agility: 2.0,
      );

      expect(stats.strength, equals(5.0));
      expect(stats.intelligence, equals(10.0));
      expect(stats.endurance, equals(3.0));
      expect(stats.charisma, equals(7.0));
      expect(stats.agility, equals(2.0));
    });

    test('total should sum all stats', () {
      final stats = CharacterStats(
        strength: 1.0,
        intelligence: 2.0,
        endurance: 3.0,
        charisma: 4.0,
        agility: 5.0,
      );

      expect(stats.total, equals(15.0));
    });

    test('getStat should return correct values', () {
      final stats = CharacterStats(
        strength: 5.0,
        intelligence: 10.0,
      );

      expect(stats.getStat(StatType.strength), equals(5.0));
      expect(stats.getStat(StatType.intelligence), equals(10.0));
      expect(stats.getStat(StatType.endurance), equals(1.0));
    });

    test('setStat should update values', () {
      final stats = CharacterStats();

      stats.setStat(StatType.strength, 10.0);
      expect(stats.strength, equals(10.0));

      stats.setStat(StatType.intelligence, 15.0);
      expect(stats.intelligence, equals(15.0));
    });

    test('addToStat should increment values', () {
      final stats = CharacterStats(strength: 5.0);

      stats.addToStat(StatType.strength, 2.5);
      expect(stats.strength, equals(7.5));

      stats.addToStat(StatType.strength, -1.0);
      expect(stats.strength, equals(6.5));
    });

    test('copyWith should create a copy with updated values', () {
      final original = CharacterStats(strength: 5.0, intelligence: 10.0);
      final copy = original.copyWith(strength: 8.0);

      expect(copy.strength, equals(8.0));
      expect(copy.intelligence, equals(10.0));
      expect(original.strength, equals(5.0)); // Original unchanged
    });
  });

  group('Character', () {
    test('should create with name and default stats', () {
      final character = Character(name: 'Test');

      expect(character.name, equals('Test'));
      expect(character.stats.strength, equals(1.0));
    });

    test('should create with custom stats', () {
      final stats = CharacterStats(strength: 10.0);
      final character = Character(name: 'Test', stats: stats);

      expect(character.stats.strength, equals(10.0));
    });
  });
}
