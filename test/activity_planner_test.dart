import 'package:flutter_test/flutter_test.dart';
import 'package:just_another_day/engine/activity_planner.dart';
import 'package:just_another_day/models/activity.dart';
import 'package:just_another_day/models/planned_activity.dart';

void main() {
  group('ActivityPlanner', () {
    late ActivityPlanner planner;

    setUp(() {
      planner = ActivityPlanner();
    });

    tearDown(() {
      planner.dispose();
    });

    test('should start empty', () {
      expect(planner.hasPlannedActivities, isFalse);
      expect(planner.queue, isEmpty);
      expect(planner.currentPlanned, isNull);
    });

    test('should add planned activities', () {
      final planned = PlannedActivity(
        activity: Activities.working,
        targetType: PlanTargetType.completions,
        targetValue: 5,
      );

      final result = planner.addPlannedActivity(planned);

      expect(result, isTrue);
      expect(planner.hasPlannedActivities, isTrue);
      expect(planner.queue.length, equals(1));
      expect(planner.currentPlanned, equals(planned));
    });

    test('should add multiple planned activities', () {
      final planned1 = PlannedActivity(
        activity: Activities.working,
        targetType: PlanTargetType.completions,
        targetValue: 5,
      );
      final planned2 = PlannedActivity(
        activity: Activities.studying,
        targetType: PlanTargetType.inGameTime,
        targetValue: 3600,
      );

      planner.addPlannedActivity(planned1);
      planner.addPlannedActivity(planned2);

      expect(planner.queue.length, equals(2));
      expect(planner.currentPlanned!.activity.id, equals('working'));
    });

    test('should not add after unlimited activity', () {
      final unlimited = PlannedActivity(
        activity: Activities.working,
        targetType: PlanTargetType.unlimited,
      );
      final other = PlannedActivity(
        activity: Activities.studying,
        targetType: PlanTargetType.completions,
        targetValue: 1,
      );

      planner.addPlannedActivity(unlimited);
      final result = planner.addPlannedActivity(other);

      expect(result, isFalse);
      expect(planner.queue.length, equals(1));
    });

    test('should allow unlimited as last activity', () {
      final first = PlannedActivity(
        activity: Activities.working,
        targetType: PlanTargetType.completions,
        targetValue: 5,
      );
      final unlimited = PlannedActivity(
        activity: Activities.studying,
        targetType: PlanTargetType.unlimited,
      );

      planner.addPlannedActivity(first);
      final result = planner.addPlannedActivity(unlimited);

      expect(result, isTrue);
      expect(planner.queue.length, equals(2));
    });

    test('should remove activity at index', () {
      final planned1 = PlannedActivity(
        activity: Activities.working,
        targetType: PlanTargetType.completions,
        targetValue: 5,
      );
      final planned2 = PlannedActivity(
        activity: Activities.studying,
        targetType: PlanTargetType.inGameTime,
        targetValue: 3600,
      );

      planner.addPlannedActivity(planned1);
      planner.addPlannedActivity(planned2);

      final removed = planner.removeAt(0);

      expect(removed, equals(planned1));
      expect(planner.queue.length, equals(1));
      expect(planner.currentPlanned!.activity.id, equals('studying'));
    });

    test('should return null when removing invalid index', () {
      final removed = planner.removeAt(0);
      expect(removed, isNull);

      planner.addPlannedActivity(
        PlannedActivity(
          activity: Activities.working,
          targetType: PlanTargetType.completions,
          targetValue: 5,
        ),
      );

      final removedInvalid = planner.removeAt(5);
      expect(removedInvalid, isNull);
    });

    test('should clear all planned activities', () {
      planner.addPlannedActivity(
        PlannedActivity(
          activity: Activities.working,
          targetType: PlanTargetType.completions,
          targetValue: 5,
        ),
      );
      planner.addPlannedActivity(
        PlannedActivity(
          activity: Activities.studying,
          targetType: PlanTargetType.inGameTime,
          targetValue: 3600,
        ),
      );

      planner.clearPlan();

      expect(planner.hasPlannedActivities, isFalse);
      expect(planner.queue, isEmpty);
    });

    test('should record completion and advance queue', () {
      final planned1 = PlannedActivity(
        activity: Activities.working,
        targetType: PlanTargetType.completions,
        targetValue: 2,
      );
      final planned2 = PlannedActivity(
        activity: Activities.studying,
        targetType: PlanTargetType.completions,
        targetValue: 1,
      );

      planner.addPlannedActivity(planned1);
      planner.addPlannedActivity(planned2);

      // First completion
      var result = planner.recordCompletion();
      expect(result, isNull);
      expect(planner.queue.length, equals(2));

      // Second completion - should complete first planned activity
      result = planner.recordCompletion();
      expect(result, equals(planned1));
      expect(planner.queue.length, equals(1));
      expect(planner.currentPlanned!.activity.id, equals('studying'));
    });

    test('should record time spent and advance queue', () {
      final planned = PlannedActivity(
        activity: Activities.working,
        targetType: PlanTargetType.inGameTime,
        targetValue: 100,
      );

      planner.addPlannedActivity(planned);

      var result = planner.recordTimeSpent(50);
      expect(result, isNull);

      result = planner.recordTimeSpent(50);
      expect(result, equals(planned));
      expect(planner.hasPlannedActivities, isFalse);
    });

    test('should estimate total time for completions', () {
      final planned = PlannedActivity(
        activity: Activities.working,
        targetType: PlanTargetType.completions,
        targetValue: 3,
      );

      planner.addPlannedActivity(planned);

      // Duration calculator that returns 10 seconds per completion
      final estimate = planner.estimateTotalTime((_) => 10);

      expect(estimate, equals(30)); // 3 completions * 10 seconds
    });

    test('should estimate total time for time-based', () {
      final planned = PlannedActivity(
        activity: Activities.working,
        targetType: PlanTargetType.inGameTime,
        targetValue: 3600,
      );

      planner.addPlannedActivity(planned);

      final estimate = planner.estimateTotalTime((_) => 10);

      expect(estimate, equals(3600)); // Exact time target
    });

    test('should return infinity for unlimited', () {
      final planned = PlannedActivity(
        activity: Activities.working,
        targetType: PlanTargetType.unlimited,
      );

      planner.addPlannedActivity(planned);

      final estimate = planner.estimateTotalTime((_) => 10);

      expect(estimate, equals(double.infinity));
    });

    test('should calculate partial progress correctly', () {
      final planned = PlannedActivity(
        activity: Activities.working,
        targetType: PlanTargetType.completions,
        targetValue: 4,
        completedValue: 1, // Already completed 1
      );

      planner.addPlannedActivity(planned);

      // Remaining: 3 completions * 10 seconds
      final estimate = planner.estimateTotalTime((_) => 10);
      expect(estimate, equals(30));
    });

    test('should serialize and restore state', () {
      final planned1 = PlannedActivity(
        activity: Activities.working,
        targetType: PlanTargetType.completions,
        targetValue: 5,
        completedValue: 2,
      );
      final planned2 = PlannedActivity(
        activity: Activities.studying,
        targetType: PlanTargetType.inGameTime,
        targetValue: 3600,
      );

      planner.addPlannedActivity(planned1);
      planner.addPlannedActivity(planned2);

      final json = planner.toJson();

      final newPlanner = ActivityPlanner();
      newPlanner.restoreFromJson(json);

      expect(newPlanner.queue.length, equals(2));
      expect(newPlanner.queue[0].activity.id, equals('working'));
      expect(newPlanner.queue[0].completedValue, equals(2));
      expect(newPlanner.queue[1].activity.id, equals('studying'));

      newPlanner.dispose();
    });

    test('should report canAddActivity correctly', () {
      expect(planner.canAddActivity(), isTrue);

      planner.addPlannedActivity(
        PlannedActivity(
          activity: Activities.working,
          targetType: PlanTargetType.completions,
          targetValue: 5,
        ),
      );
      expect(planner.canAddActivity(), isTrue);

      planner.addPlannedActivity(
        PlannedActivity(
          activity: Activities.studying,
          targetType: PlanTargetType.unlimited,
        ),
      );
      expect(planner.canAddActivity(), isFalse);
    });

    test('should report isCurrentUnlimited correctly', () {
      expect(planner.isCurrentUnlimited, isFalse);

      planner.addPlannedActivity(
        PlannedActivity(
          activity: Activities.working,
          targetType: PlanTargetType.unlimited,
        ),
      );
      expect(planner.isCurrentUnlimited, isTrue);
    });

    test('should notify listeners on changes', () {
      var notifyCount = 0;
      planner.addListener(() => notifyCount++);

      planner.addPlannedActivity(
        PlannedActivity(
          activity: Activities.working,
          targetType: PlanTargetType.completions,
          targetValue: 2,
        ),
      );
      expect(notifyCount, equals(1));

      planner.recordCompletion();
      expect(notifyCount, equals(2));

      planner.recordCompletion(); // Completes and removes
      expect(notifyCount, equals(3));

      planner.clearPlan();
      expect(notifyCount, equals(4));
    });
  });
}
