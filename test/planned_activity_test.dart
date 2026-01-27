import 'package:flutter_test/flutter_test.dart';
import 'package:just_another_day/models/activity.dart';
import 'package:just_another_day/models/planned_activity.dart';

void main() {
  group('PlannedActivity', () {
    test('should create with completions target', () {
      final planned = PlannedActivity(
        activity: Activities.working,
        targetType: PlanTargetType.completions,
        targetValue: 5,
      );

      expect(planned.activity.id, equals('working'));
      expect(planned.targetType, equals(PlanTargetType.completions));
      expect(planned.targetValue, equals(5));
      expect(planned.completedValue, equals(0));
      expect(planned.isComplete, isFalse);
      expect(planned.progress, equals(0));
    });

    test('should create with in-game time target', () {
      final planned = PlannedActivity(
        activity: Activities.studying,
        targetType: PlanTargetType.inGameTime,
        targetValue: 3600, // 1 hour in-game
      );

      expect(planned.targetType, equals(PlanTargetType.inGameTime));
      expect(planned.targetValue, equals(3600));
    });

    test('should create with unlimited target', () {
      final planned = PlannedActivity(
        activity: Activities.exercising,
        targetType: PlanTargetType.unlimited,
      );

      expect(planned.targetType, equals(PlanTargetType.unlimited));
      expect(planned.isComplete, isFalse);
      expect(planned.progress, equals(0));
      expect(planned.remainingValue, equals(double.infinity));
    });

    test('should record completion correctly', () {
      final planned = PlannedActivity(
        activity: Activities.working,
        targetType: PlanTargetType.completions,
        targetValue: 3,
      );

      planned.recordCompletion();
      expect(planned.completedValue, equals(1));
      expect(planned.progress, closeTo(0.333, 0.01));
      expect(planned.isComplete, isFalse);

      planned.recordCompletion();
      planned.recordCompletion();
      expect(planned.completedValue, equals(3));
      expect(planned.progress, equals(1.0));
      expect(planned.isComplete, isTrue);
    });

    test('should record time spent correctly', () {
      final planned = PlannedActivity(
        activity: Activities.working,
        targetType: PlanTargetType.inGameTime,
        targetValue: 100,
      );

      planned.recordTimeSpent(30);
      expect(planned.completedValue, equals(30));
      expect(planned.progress, closeTo(0.3, 0.01));
      expect(planned.remainingValue, equals(70));

      planned.recordTimeSpent(70);
      expect(planned.completedValue, equals(100));
      expect(planned.isComplete, isTrue);
    });

    test('should not record completions for time-based target', () {
      final planned = PlannedActivity(
        activity: Activities.working,
        targetType: PlanTargetType.inGameTime,
        targetValue: 100,
      );

      planned.recordCompletion();
      expect(planned.completedValue, equals(0));
    });

    test('should not record time for completion-based target', () {
      final planned = PlannedActivity(
        activity: Activities.working,
        targetType: PlanTargetType.completions,
        targetValue: 5,
      );

      planned.recordTimeSpent(100);
      expect(planned.completedValue, equals(0));
    });

    test('should serialize to JSON correctly', () {
      final planned = PlannedActivity(
        activity: Activities.working,
        targetType: PlanTargetType.completions,
        targetValue: 5,
        completedValue: 2,
      );

      final json = planned.toJson();
      expect(json['activityId'], equals('working'));
      expect(json['targetType'], equals('completions'));
      expect(json['targetValue'], equals(5));
      expect(json['completedValue'], equals(2));
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'activityId': 'studying',
        'targetType': 'inGameTime',
        'targetValue': 3600.0,
        'completedValue': 1800.0,
      };

      final planned = PlannedActivity.fromJson(json);
      expect(planned.activity.id, equals('studying'));
      expect(planned.targetType, equals(PlanTargetType.inGameTime));
      expect(planned.targetValue, equals(3600));
      expect(planned.completedValue, equals(1800));
    });

    test('should generate correct target description for completions', () {
      final planned = PlannedActivity(
        activity: Activities.working,
        targetType: PlanTargetType.completions,
        targetValue: 5,
        completedValue: 2,
      );

      expect(planned.targetDescription, equals('2 / 5 completions'));
    });

    test('should generate correct target description for time', () {
      final planned = PlannedActivity(
        activity: Activities.working,
        targetType: PlanTargetType.inGameTime,
        targetValue: 3600,
        completedValue: 1800,
      );

      expect(planned.targetDescription, equals('30m 0s / 1h 0m'));
    });

    test('should generate correct target description for unlimited', () {
      final planned = PlannedActivity(
        activity: Activities.working,
        targetType: PlanTargetType.unlimited,
      );

      expect(planned.targetDescription, equals('Unlimited'));
    });

    test('should create copy with modified values', () {
      final original = PlannedActivity(
        activity: Activities.working,
        targetType: PlanTargetType.completions,
        targetValue: 5,
      );

      final copy = original.copyWith(targetValue: 10);
      expect(copy.targetValue, equals(10));
      expect(copy.activity.id, equals('working'));
      expect(copy.targetType, equals(PlanTargetType.completions));
    });
  });
}
