import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_another_day/engine/activity_manager.dart';
import 'package:just_another_day/engine/game_loop.dart';
import 'package:just_another_day/models/activity.dart';
import 'package:just_another_day/models/character.dart';
import 'package:just_another_day/models/planned_activity.dart';

/// A fake ticker for testing that allows manual time control.
class FakeTicker implements Ticker {
  FakeTicker(this._onTick);

  final TickerCallback _onTick;
  bool _isActive = false;
  Duration _elapsed = Duration.zero;

  @override
  bool get isActive => _isActive;

  @override
  bool get isTicking => _isActive && !_muted;

  bool _muted = false;

  @override
  bool get muted => _muted;

  @override
  set muted(bool value) => _muted = value;

  @override
  TickerFuture start() {
    _isActive = true;
    _elapsed = Duration.zero;
    return TickerFuture.complete();
  }

  @override
  void stop({bool canceled = false}) {
    _isActive = false;
  }

  @override
  void dispose() {
    _isActive = false;
  }

  /// Advances time by the given duration and triggers a tick.
  void advance(Duration duration) {
    if (!_isActive || _muted) return;
    _elapsed += duration;
    _onTick(_elapsed);
  }

  @override
  void absorbTicker(Ticker originalTicker) {}

  @override
  String? debugLabel;

  @override
  bool get scheduled => _isActive;

  @override
  bool get shouldScheduleTick => _isActive && !_muted;

  @override
  void scheduleTick({bool rescheduling = false}) {}

  @override
  void unscheduleTick() {}

  @override
  String toString({bool debugIncludeStack = false}) => 'FakeTicker';

  @override
  DiagnosticsNode describeForError(String name) {
    return DiagnosticsProperty<Ticker>(name, this);
  }
}

/// A fake ticker provider for testing.
class FakeTickerProvider implements TickerProvider {
  FakeTicker? _ticker;

  FakeTicker? get ticker => _ticker;

  @override
  Ticker createTicker(TickerCallback onTick) {
    _ticker = FakeTicker(onTick);
    return _ticker!;
  }
}

void main() {
  group('ActivityManager partial progress', () {
    late FakeTickerProvider tickerProvider;
    late GameLoop gameLoop;
    late Character character;
    late ActivityManager activityManager;

    setUp(() {
      tickerProvider = FakeTickerProvider();
      gameLoop = GameLoop(vsync: tickerProvider);
      character = Character(name: 'TestPlayer');
      activityManager = ActivityManager(
        character: character,
        gameLoop: gameLoop,
      );
      gameLoop.start();
    });

    tearDown(() {
      activityManager.dispose();
      gameLoop.dispose();
    });

    test('should save partial progress when switching activities', () {
      // Start working activity
      activityManager.startActivity(Activities.working, force: true);

      // Advance time to get 50% progress
      // Working: baseDuration=10, difficulty=0.5, primary=endurance
      // With endurance=1: duration = 10 * (0.5/1) = 5 seconds
      // For 50% progress: need 2.5 seconds = 2500ms
      tickerProvider.ticker!.advance(const Duration(milliseconds: 2500));

      expect(activityManager.currentProgress!.progress, closeTo(0.5, 0.01));

      // Now switch to studying - should save working progress
      activityManager.startActivity(Activities.studying, force: true);

      // Check that working progress was saved
      expect(character.getSavedProgress('working'), closeTo(0.5, 0.01));

      // Current activity should now be studying
      expect(activityManager.currentActivity!.id, equals('studying'));
    });

    test('should restore saved progress when returning to activity', () {
      // Start working and get some progress
      // Working: baseDuration=10, difficulty=0.5, duration = 5 seconds
      // For 50% progress: need 2.5 seconds = 2500ms
      activityManager.startActivity(Activities.working, force: true);
      tickerProvider.ticker!.advance(const Duration(milliseconds: 2500));
      expect(activityManager.currentProgress!.progress, closeTo(0.5, 0.01));

      // Switch to studying
      activityManager.startActivity(Activities.studying, force: true);
      expect(character.getSavedProgress('working'), closeTo(0.5, 0.01));

      // Switch back to working - should restore progress
      activityManager.startActivity(Activities.working, force: true);

      // Saved progress should be cleared
      expect(character.getSavedProgress('working'), equals(0.0));

      // Progress should be restored
      expect(activityManager.currentProgress!.progress, closeTo(0.5, 0.01));
    });

    test('should clear saved progress when activity completes', () {
      // Pre-save some progress
      character.saveActivityProgress('working', 0.9);

      // Start working with saved progress
      activityManager.startActivity(Activities.working, force: true);

      // Progress should start at 0.9 (45 seconds of 50 total)
      expect(activityManager.currentProgress!.progress, closeTo(0.9, 0.01));

      // Complete the remaining 10% (5 seconds = 5000ms)
      tickerProvider.ticker!.advance(const Duration(milliseconds: 5000));

      // Activity should be complete
      expect(activityManager.currentProgress, isNull);

      // Saved progress should be cleared
      expect(character.getSavedProgress('working'), equals(0.0));
    });

    test('should save progress when stopping activity', () {
      // Start working activity
      activityManager.startActivity(Activities.working, force: true);

      // Advance time to get 30% progress
      // Working: duration = 5 seconds, 30% = 1.5 seconds = 1500ms
      tickerProvider.ticker!.advance(const Duration(milliseconds: 1500));

      expect(activityManager.currentProgress!.progress, closeTo(0.3, 0.01));

      // Stop activity - should save progress by default
      activityManager.stopActivity();

      // Check that progress was saved
      expect(character.getSavedProgress('working'), closeTo(0.3, 0.01));
    });

    test('should not save progress when stopping with grantPartialRewards', () {
      // Start working activity
      activityManager.startActivity(Activities.working, force: true);

      // Advance time to get 30% progress (1.5 seconds = 1500ms)
      tickerProvider.ticker!.advance(const Duration(milliseconds: 1500));

      // Stop activity with partial rewards (don't save progress)
      activityManager.stopActivity(grantPartialRewards: true);

      // Progress should NOT be saved when granting partial rewards
      expect(character.getSavedProgress('working'), equals(0.0));
    });

    test('should not save progress when stopping with saveProgress=false', () {
      // Start working activity
      activityManager.startActivity(Activities.working, force: true);

      // Advance time to get 30% progress (1.5 seconds = 1500ms)
      tickerProvider.ticker!.advance(const Duration(milliseconds: 1500));

      // Stop activity without saving progress
      activityManager.stopActivity(saveProgress: false);

      // Progress should NOT be saved
      expect(character.getSavedProgress('working'), equals(0.0));
    });

    test('should not save progress when switching to same activity', () {
      // Start working activity
      activityManager.startActivity(Activities.working, force: true);

      // Advance time to get 50% progress (2.5 seconds = 2500ms)
      tickerProvider.ticker!.advance(const Duration(milliseconds: 2500));

      // Try to "switch" to the same activity with force
      // This should continue the activity, not save/reset
      final initialProgress = activityManager.currentProgress!.progress;

      // Actually, with force=true it restarts. Let's test without force first
      // to confirm it doesn't switch when activity is same
      final result = activityManager.startActivity(Activities.working);
      expect(result, isFalse); // Can't start - already running

      // Progress should remain unchanged
      expect(
        activityManager.currentProgress!.progress,
        closeTo(initialProgress, 0.01),
      );
    });

    test('partial progress should persist through save/restore', () {
      // Start working and get 50% progress (2.5 seconds = 2500ms)
      activityManager.startActivity(Activities.working, force: true);
      tickerProvider.ticker!.advance(const Duration(milliseconds: 2500));

      // Switch to studying to save working progress
      activityManager.startActivity(Activities.studying, force: true);

      // Simulate save/restore cycle
      final savedJson = character.toJson();
      final restoredCharacter = Character.fromJson(savedJson);

      // Verify progress was preserved
      expect(restoredCharacter.getSavedProgress('working'), closeTo(0.5, 0.01));
    });

    test('multiple activities should track progress independently', () {
      // Start working and get 50% progress (2.5 seconds = 2500ms)
      activityManager.startActivity(Activities.working, force: true);
      tickerProvider.ticker!.advance(const Duration(milliseconds: 2500));

      // Switch to studying
      activityManager.startActivity(Activities.studying, force: true);

      // Get 30% progress on studying
      // Studying: baseDuration=15, difficulty=0.8, primary=intelligence
      // With intelligence=1: duration = 15 * (0.8/1) = 12 seconds
      // For 30% progress: need 3.6 seconds = 3600ms
      tickerProvider.ticker!.advance(const Duration(milliseconds: 3600));

      // Switch to exercising
      activityManager.startActivity(Activities.exercising, force: true);

      // Both working and studying should have saved progress
      expect(character.getSavedProgress('working'), closeTo(0.5, 0.01));
      expect(character.getSavedProgress('studying'), closeTo(0.3, 0.01));
    });
  });

  group('ActivityManager plan time estimation', () {
    late FakeTickerProvider tickerProvider;
    late GameLoop gameLoop;
    late Character character;
    late ActivityManager activityManager;

    setUp(() {
      tickerProvider = FakeTickerProvider();
      gameLoop = GameLoop(vsync: tickerProvider);
      character = Character(name: 'TestPlayer');
      activityManager = ActivityManager(
        character: character,
        gameLoop: gameLoop,
      );
      gameLoop.start();
    });

    tearDown(() {
      activityManager.dispose();
      gameLoop.dispose();
    });

    test('should account for difficulty and stats evolution in estimation', () {
      // Add 3 completions of working
      // Working: baseDuration=10, difficulty=0.5, primary=endurance
      // Working rewards: endurance +0.1, charisma +0.05
      final planned = PlannedActivity(
        activity: Activities.working,
        targetType: PlanTargetType.completions,
        targetValue: 3,
      );

      activityManager.planner.addPlannedActivity(planned);

      // With endurance=1.0:
      // Completion 1: coef=1.0, end=1.0, dur = 10 * (0.5*1.0/1.0) = 5.0s
      //   After: endurance = 1.1, completions = 1
      // Completion 2: coef=1.1, end=1.1, dur = 10 * (0.5*1.1/1.1) = 5.0s
      //   After: endurance = 1.2, completions = 2
      // Completion 3: coef=1.21, end=1.2, dur = 10 * (0.5*1.21/1.2) = 5.04s
      // Total = 5.0 + 5.0 + 5.04 = 15.04s
      // Note: difficulty increase and stat increase roughly cancel out early on
      final estimate = activityManager.estimatePlanTime();
      expect(estimate, closeTo(15.04, 0.1));
    });

    test('should handle existing completions in estimation', () {
      // Pre-add some completions
      character.addCompletion('working');
      character.addCompletion('working');
      // Current coefficient for working = 1.1^2 = 1.21

      final planned = PlannedActivity(
        activity: Activities.working,
        targetType: PlanTargetType.completions,
        targetValue: 2,
      );

      activityManager.planner.addPlannedActivity(planned);

      // With endurance=1.0, existing completions=2:
      // Completion 1: coef=1.21, dur = 10 * (0.5*1.21/1.0) = 6.05s
      //   After: endurance = 1.1, completions = 3
      // Completion 2: coef=1.331, end=1.1, dur = 10 * (0.5*1.331/1.1) = 6.05s
      final estimate = activityManager.estimatePlanTime();
      expect(estimate, closeTo(12.1, 0.2));
    });

    test('should estimate time-based targets with evolving stats', () {
      final planned = PlannedActivity(
        activity: Activities.working,
        targetType: PlanTargetType.inGameTime,
        targetValue: 15, // 15 seconds of in-game time
      );

      activityManager.planner.addPlannedActivity(planned);

      // Should account for completions happening within the time window
      // and update stats/difficulty accordingly
      final estimate = activityManager.estimatePlanTime();

      // First completion takes 5s, second takes ~5s (stats offset difficulty)
      // Third completion starts but only partial time remains
      expect(estimate, equals(15)); // Time-based should equal target time
    });

    test('should handle multiple planned activities with evolution', () {
      // First: 2 completions of working
      final planned1 = PlannedActivity(
        activity: Activities.working,
        targetType: PlanTargetType.completions,
        targetValue: 2,
      );

      // Second: 2 completions of studying
      final planned2 = PlannedActivity(
        activity: Activities.studying,
        targetType: PlanTargetType.completions,
        targetValue: 2,
      );

      activityManager.planner.addPlannedActivity(planned1);
      activityManager.planner.addPlannedActivity(planned2);

      final estimate = activityManager.estimatePlanTime();

      // Working improves endurance, studying uses intelligence
      // Stats from working don't directly help studying
      // But the estimation should still be reasonable
      expect(estimate, greaterThan(0));
      expect(estimate.isFinite, isTrue);
    });

    test('should return infinity for unlimited activities', () {
      final planned = PlannedActivity(
        activity: Activities.working,
        targetType: PlanTargetType.unlimited,
      );

      activityManager.planner.addPlannedActivity(planned);

      final estimate = activityManager.estimatePlanTime();
      expect(estimate, equals(double.infinity));
    });

    test('should return 0 for empty plan', () {
      final estimate = activityManager.estimatePlanTime();
      expect(estimate, equals(0));
    });
  });

  group('ActivityManager removePlannedActivity', () {
    late FakeTickerProvider tickerProvider;
    late GameLoop gameLoop;
    late Character character;
    late ActivityManager activityManager;

    setUp(() {
      tickerProvider = FakeTickerProvider();
      gameLoop = GameLoop(vsync: tickerProvider);
      character = Character(name: 'TestPlayer');
      activityManager = ActivityManager(
        character: character,
        gameLoop: gameLoop,
      );
      gameLoop.start();
    });

    tearDown(() {
      activityManager.dispose();
      gameLoop.dispose();
    });

    test('should remove non-current activity without affecting current', () {
      // Add two activities to plan
      activityManager.planner.addPlannedActivity(
        PlannedActivity(
          activity: Activities.working,
          targetType: PlanTargetType.completions,
          targetValue: 2,
        ),
      );
      activityManager.planner.addPlannedActivity(
        PlannedActivity(
          activity: Activities.studying,
          targetType: PlanTargetType.completions,
          targetValue: 1,
        ),
      );

      // Start the plan
      activityManager.startPlan();
      expect(activityManager.currentActivity?.id, equals('working'));
      expect(activityManager.planner.queue.length, equals(2));

      // Remove the second (non-current) activity
      final removed = activityManager.removePlannedActivity(1);

      expect(removed?.activity.id, equals('studying'));
      expect(activityManager.planner.queue.length, equals(1));
      // Current activity should still be running
      expect(activityManager.currentActivity?.id, equals('working'));
      expect(activityManager.hasActiveActivity, isTrue);
    });

    test(
      'should stop current activity and move to next when removing first',
      () {
        // Add two activities to plan
        activityManager.planner.addPlannedActivity(
          PlannedActivity(
            activity: Activities.working,
            targetType: PlanTargetType.completions,
            targetValue: 2,
          ),
        );
        activityManager.planner.addPlannedActivity(
          PlannedActivity(
            activity: Activities.studying,
            targetType: PlanTargetType.completions,
            targetValue: 1,
          ),
        );

        // Start the plan
        activityManager.startPlan();
        expect(activityManager.currentActivity?.id, equals('working'));

        // Get some progress on working
        tickerProvider.ticker!.advance(const Duration(milliseconds: 2000));
        expect(activityManager.currentProgress!.progress, greaterThan(0));

        // Remove the current (first) activity
        final removed = activityManager.removePlannedActivity(0);

        expect(removed?.activity.id, equals('working'));
        expect(activityManager.planner.queue.length, equals(1));
        // Should have moved to studying
        expect(activityManager.currentActivity?.id, equals('studying'));
        expect(activityManager.hasActiveActivity, isTrue);
        // Progress should be saved for working
        expect(character.getSavedProgress('working'), greaterThan(0));
      },
    );

    test('should stop activity when removing only planned activity', () {
      // Add one activity to plan
      activityManager.planner.addPlannedActivity(
        PlannedActivity(
          activity: Activities.working,
          targetType: PlanTargetType.completions,
          targetValue: 2,
        ),
      );

      // Start the plan
      activityManager.startPlan();
      expect(activityManager.currentActivity?.id, equals('working'));

      // Get some progress
      tickerProvider.ticker!.advance(const Duration(milliseconds: 2000));

      // Remove the only activity
      final removed = activityManager.removePlannedActivity(0);

      expect(removed?.activity.id, equals('working'));
      expect(activityManager.planner.queue.length, equals(0));
      // Should have stopped - no more activities
      expect(activityManager.hasActiveActivity, isFalse);
      // Progress should be saved
      expect(character.getSavedProgress('working'), greaterThan(0));
    });

    test('should return null for invalid index', () {
      activityManager.planner.addPlannedActivity(
        PlannedActivity(
          activity: Activities.working,
          targetType: PlanTargetType.completions,
          targetValue: 1,
        ),
      );

      expect(activityManager.removePlannedActivity(-1), isNull);
      expect(activityManager.removePlannedActivity(5), isNull);
      expect(activityManager.planner.queue.length, equals(1));
    });

    test('should not affect activity if plan not started', () {
      // Add activities but don't start the plan
      activityManager.planner.addPlannedActivity(
        PlannedActivity(
          activity: Activities.working,
          targetType: PlanTargetType.completions,
          targetValue: 2,
        ),
      );
      activityManager.planner.addPlannedActivity(
        PlannedActivity(
          activity: Activities.studying,
          targetType: PlanTargetType.completions,
          targetValue: 1,
        ),
      );

      expect(activityManager.hasActiveActivity, isFalse);

      // Remove first activity
      final removed = activityManager.removePlannedActivity(0);

      expect(removed?.activity.id, equals('working'));
      expect(activityManager.planner.queue.length, equals(1));
      expect(activityManager.planner.currentPlanned?.activity.id, 'studying');
      // Still no active activity
      expect(activityManager.hasActiveActivity, isFalse);
    });
  });
}
