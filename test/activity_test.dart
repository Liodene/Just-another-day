import 'package:flutter_test/flutter_test.dart';
import 'package:just_another_day/models/activity.dart';
import 'package:just_another_day/models/character.dart';

void main() {
  group('Activity', () {
    late Activity testActivity;

    setUp(() {
      testActivity = const Activity(
        id: 'test',
        name: 'Test Activity',
        description: 'A test activity',
        baseDuration: 10.0,
        difficulty: 5.0,
        primaryStat: StatType.strength,
        rewards: {
          StatType.strength: 0.5,
          StatType.endurance: 0.2,
        },
      );
    });

    test('calculateDuration should scale with character stats', () {
      // With strength = 1, difficulty = 5: duration = 10 * (5/1) = 50
      final weakStats = CharacterStats(strength: 1.0);
      expect(testActivity.calculateDuration(weakStats), equals(50.0));

      // With strength = 5, difficulty = 5: duration = 10 * (5/5) = 10
      final matchedStats = CharacterStats(strength: 5.0);
      expect(testActivity.calculateDuration(matchedStats), equals(10.0));

      // With strength = 10, difficulty = 5: duration = 10 * (5/10) = 5
      final strongStats = CharacterStats(strength: 10.0);
      expect(testActivity.calculateDuration(strongStats), equals(5.0));
    });

    test('calculateDuration should clamp multiplier', () {
      // Very high stats should not reduce below 10% of base
      final veryStrongStats = CharacterStats(strength: 100.0);
      final duration = testActivity.calculateDuration(veryStrongStats);
      expect(duration, greaterThanOrEqualTo(1.0)); // 10% of 10
    });

    test('meetsRequirements should check all requirements', () {
      const activityWithRequirements = Activity(
        id: 'advanced',
        name: 'Advanced',
        description: 'Requires high stats',
        baseDuration: 10.0,
        difficulty: 10.0,
        primaryStat: StatType.strength,
        rewards: {},
        requirements: {
          StatType.strength: 5.0,
          StatType.intelligence: 3.0,
        },
      );

      // Does not meet requirements
      final weakStats = CharacterStats(strength: 2.0, intelligence: 1.0);
      expect(
        activityWithRequirements.meetsRequirements(weakStats),
        isFalse,
      );

      // Partially meets requirements
      final partialStats = CharacterStats(strength: 5.0, intelligence: 1.0);
      expect(
        activityWithRequirements.meetsRequirements(partialStats),
        isFalse,
      );

      // Meets requirements
      final strongStats = CharacterStats(strength: 5.0, intelligence: 3.0);
      expect(
        activityWithRequirements.meetsRequirements(strongStats),
        isTrue,
      );

      // Exceeds requirements
      final veryStrongStats = CharacterStats(
        strength: 10.0,
        intelligence: 10.0,
      );
      expect(
        activityWithRequirements.meetsRequirements(veryStrongStats),
        isTrue,
      );
    });

    test('meetsRequirements should return true when no requirements', () {
      final stats = CharacterStats();
      expect(testActivity.meetsRequirements(stats), isTrue);
    });
  });

  group('ActivityProgress', () {
    late Activity testActivity;

    setUp(() {
      testActivity = const Activity(
        id: 'test',
        name: 'Test',
        description: 'Test',
        baseDuration: 10.0,
        difficulty: 5.0,
        primaryStat: StatType.strength,
        rewards: {},
      );
    });

    test('should start with zero elapsed time', () {
      final progress = ActivityProgress(
        activity: testActivity,
        totalDuration: 10.0,
      );

      expect(progress.elapsedTime, equals(0.0));
      expect(progress.progress, equals(0.0));
      expect(progress.isComplete, isFalse);
    });

    test('update should advance elapsed time', () {
      final progress = ActivityProgress(
        activity: testActivity,
        totalDuration: 10.0,
      );

      progress.update(2.5);
      expect(progress.elapsedTime, equals(2.5));
      expect(progress.progress, closeTo(0.25, 0.001));
    });

    test('update should return true when completing', () {
      final progress = ActivityProgress(
        activity: testActivity,
        totalDuration: 10.0,
      );

      var completed = progress.update(5.0);
      expect(completed, isFalse);
      expect(progress.isComplete, isFalse);

      completed = progress.update(5.0);
      expect(completed, isTrue);
      expect(progress.isComplete, isTrue);
    });

    test('progress should be clamped to 1.0', () {
      final progress = ActivityProgress(
        activity: testActivity,
        totalDuration: 10.0,
      );

      progress.update(15.0);
      expect(progress.progress, equals(1.0));
    });

    test('remainingTime should decrease', () {
      final progress = ActivityProgress(
        activity: testActivity,
        totalDuration: 10.0,
      );

      expect(progress.remainingTime, equals(10.0));

      progress.update(3.0);
      expect(progress.remainingTime, equals(7.0));

      progress.update(7.0);
      expect(progress.remainingTime, equals(0.0));
    });
  });

  group('Activities', () {
    test('should have pre-defined activities', () {
      expect(Activities.all, isNotEmpty);
      expect(Activities.working.id, equals('working'));
      expect(Activities.studying.id, equals('studying'));
      expect(Activities.exercising.id, equals('exercising'));
    });

    test('getById should return correct activity', () {
      expect(Activities.getById('working'), equals(Activities.working));
      expect(Activities.getById('studying'), equals(Activities.studying));
      expect(Activities.getById('nonexistent'), isNull);
    });

    test('all activities should have valid properties', () {
      for (final activity in Activities.all) {
        expect(activity.id, isNotEmpty);
        expect(activity.name, isNotEmpty);
        expect(activity.description, isNotEmpty);
        expect(activity.baseDuration, greaterThan(0));
        expect(activity.difficulty, greaterThan(0));
        expect(activity.rewards, isNotEmpty);
      }
    });
  });
}
