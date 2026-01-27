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
      expect(character.totalCompletions, equals(0));
    });

    test('should create with custom stats', () {
      final stats = CharacterStats(strength: 10.0);
      final character = Character(name: 'Test', stats: stats);

      expect(character.stats.strength, equals(10.0));
    });

    test('should track completions per activity', () {
      final character = Character(name: 'Test');

      expect(character.getCompletions('working'), equals(0));
      expect(character.getCompletions('studying'), equals(0));

      character.addCompletion('working');
      character.addCompletion('working');
      character.addCompletion('studying');

      expect(character.getCompletions('working'), equals(2));
      expect(character.getCompletions('studying'), equals(1));
      expect(character.totalCompletions, equals(3));
    });

    test('getDifficultyCoefficient should be 1.0 with 0 completions', () {
      final character = Character(name: 'Test');

      expect(character.getDifficultyCoefficient('working'), equals(1.0));
    });

    test('getDifficultyCoefficient should be 1.10 with 1 completion', () {
      final character = Character(name: 'Test');
      character.addCompletion('working');

      expect(
        character.getDifficultyCoefficient('working'),
        closeTo(1.10, 0.001),
      );
    });

    test('getDifficultyCoefficient should be 1.21 with 2 completions', () {
      final character = Character(name: 'Test');
      character.addCompletion('working');
      character.addCompletion('working');

      expect(
        character.getDifficultyCoefficient('working'),
        closeTo(1.21, 0.001),
      );
    });

    test('getDifficultyCoefficient should scale exponentially', () {
      final character = Character(
        name: 'Test',
        activityCompletions: {'working': 10},
      );

      // 1.10^10 = 2.5937424601
      expect(
        character.getDifficultyCoefficient('working'),
        closeTo(2.594, 0.001),
      );
    });

    test('difficulty coefficients are independent per activity', () {
      final character = Character(name: 'Test');

      character.addCompletion('working');
      character.addCompletion('working');
      character.addCompletion('studying');

      // Working: 2 completions = 1.21x
      expect(
        character.getDifficultyCoefficient('working'),
        closeTo(1.21, 0.001),
      );
      // Studying: 1 completion = 1.10x
      expect(
        character.getDifficultyCoefficient('studying'),
        closeTo(1.10, 0.001),
      );
      // Exercising: 0 completions = 1.0x
      expect(
        character.getDifficultyCoefficient('exercising'),
        equals(1.0),
      );
    });
  });

  group('Character saved activity progress', () {
    test('should return 0.0 for unsaved progress', () {
      final character = Character(name: 'Test');

      expect(character.getSavedProgress('working'), equals(0.0));
      expect(character.getSavedProgress('studying'), equals(0.0));
    });

    test('should save and retrieve partial progress', () {
      final character = Character(name: 'Test');

      character.saveActivityProgress('working', 0.5);

      expect(character.getSavedProgress('working'), equals(0.5));
      expect(character.getSavedProgress('studying'), equals(0.0));
    });

    test('should not save zero progress', () {
      final character = Character(name: 'Test');

      character.saveActivityProgress('working', 0.0);

      expect(character.savedActivityProgress.containsKey('working'), isFalse);
    });

    test('should not save complete progress (1.0)', () {
      final character = Character(name: 'Test');

      character.saveActivityProgress('working', 1.0);

      expect(character.savedActivityProgress.containsKey('working'), isFalse);
    });

    test('should clear saved progress', () {
      final character = Character(name: 'Test');

      character.saveActivityProgress('working', 0.75);
      expect(character.getSavedProgress('working'), equals(0.75));

      character.clearSavedProgress('working');
      expect(character.getSavedProgress('working'), equals(0.0));
    });

    test('should track multiple activities independently', () {
      final character = Character(name: 'Test');

      character.saveActivityProgress('working', 0.25);
      character.saveActivityProgress('studying', 0.75);

      expect(character.getSavedProgress('working'), equals(0.25));
      expect(character.getSavedProgress('studying'), equals(0.75));

      character.clearSavedProgress('working');

      expect(character.getSavedProgress('working'), equals(0.0));
      expect(character.getSavedProgress('studying'), equals(0.75));
    });

    test('should create with initial saved progress', () {
      final character = Character(
        name: 'Test',
        savedActivityProgress: {'working': 0.5, 'studying': 0.3},
      );

      expect(character.getSavedProgress('working'), equals(0.5));
      expect(character.getSavedProgress('studying'), equals(0.3));
    });
  });
}
