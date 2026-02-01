import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_another_day/engine/activity_manager.dart';
import 'package:just_another_day/engine/game_loop.dart';
import 'package:just_another_day/models/activity.dart';
import 'package:just_another_day/models/character.dart';
import 'package:just_another_day/models/game_time.dart';
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

    test('should account for difficulty increase in estimation', () {
      // Add 3 completions of working
      // Working: baseDuration=10, difficulty=0.5, primary=endurance
      // Stats don't evolve during the day anymore, only difficulty increases
      final planned = PlannedActivity(
        activity: Activities.working,
        targetType: PlanTargetType.completions,
        targetValue: 3,
      );

      activityManager.planner.addPlannedActivity(planned);

      // With endurance=1.0, stats fixed during day:
      // Completion 1: coef=1.0, dur = 10 * (0.5*1.0/1.0) = 5.0s
      // Completion 2: coef=1.1, dur = 10 * (0.5*1.1/1.0) = 5.5s
      // Completion 3: coef=1.21, dur = 10 * (0.5*1.21/1.0) = 6.05s
      // Total = 5.0 + 5.5 + 6.05 = 16.55s
      final estimate = activityManager.estimatePlanTime();
      expect(estimate.inMicroseconds / 1000000, closeTo(16.55, 0.1));
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
      // Completion 2: coef=1.331, dur = 10 * (0.5*1.331/1.0) = 6.655s
      final estimate = activityManager.estimatePlanTime();
      expect(estimate.inMicroseconds / 1000000, closeTo(12.7, 0.2));
    });

    test('should estimate time-based targets simply', () {
      final planned = PlannedActivity(
        activity: Activities.working,
        targetType: PlanTargetType.inGameTime,
        targetValue: 15, // 15 seconds of in-game time
      );

      activityManager.planner.addPlannedActivity(planned);

      // For time-based targets, the estimate is simply the target time
      // (simplified since stats don't evolve during the day)
      final estimate = activityManager.estimatePlanTime();
      expect(estimate, equals(const Duration(seconds: 15)));
    });

    test('should handle multiple planned activities', () {
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

      // Estimation only considers difficulty increases, not stat changes
      expect(estimate, greaterThan(Duration.zero));
      expect(estimate.inMicroseconds, isPositive);
    });

    test('should return infinity for unlimited activities', () {
      final planned = PlannedActivity(
        activity: Activities.working,
        targetType: PlanTargetType.unlimited,
      );

      activityManager.planner.addPlannedActivity(planned);

      final estimate = activityManager.estimatePlanTime();
      expect(estimate, equals(const Duration(days: 365 * 100))); // Effectively infinite
    });

    test('should return 0 for empty plan', () {
      final estimate = activityManager.estimatePlanTime();
      expect(estimate, equals(Duration.zero));
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

  group('ActivityManager daily gains and day expiration', () {
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

    test('should track daily completions instead of applying immediately', () {
      // Initial stats
      final initialEndurance = character.stats.endurance;

      // Start working activity and complete it
      activityManager.startActivity(Activities.working, force: true);

      // Working: duration = 5 seconds = 5000ms
      tickerProvider.ticker!.advance(const Duration(milliseconds: 5000));

      // Stats should NOT have changed yet
      expect(character.stats.endurance, equals(initialEndurance));

      // But daily completions should be tracked
      expect(activityManager.dailyCompletions['working'], equals(1));

      // And daily gains should show the expected gains
      expect(activityManager.dailyGains.isNotEmpty, isTrue);
      expect(activityManager.dailyGains[StatType.endurance], greaterThan(0));
    });

    test('startNewDay should apply gains only for new levels above record', () {
      final initialEndurance = character.stats.endurance;

      // Enable auto-repeat to complete multiple times
      activityManager.autoRepeat = true;
      activityManager.startActivity(Activities.working, force: true);

      // Working: duration starts at ~5s, increases with each completion
      // Advance in small increments to allow multiple completions
      // Complete 3 times (need ~17s total with increasing difficulty)
      for (var i = 0; i < 20; i++) {
        tickerProvider.ticker!.advance(const Duration(milliseconds: 1000));
      }

      expect(activityManager.dailyCompletions['working'], equals(3));

      // Get the expected gains (3 new levels, since record is 0)
      final expectedGains = activityManager.dailyGains;
      expect(expectedGains[StatType.endurance], greaterThan(0));

      // Start a new day
      activityManager.startNewDay();

      // Stats should now be applied
      expect(character.stats.endurance, greaterThan(initialEndurance));

      // Record should be updated
      expect(character.getCompletionRecord('working'), equals(3));

      // Daily completions should be cleared
      expect(activityManager.dailyCompletions.isEmpty, isTrue);
    });

    test('should not gain stats if completions are below record', () {
      // Set a pre-existing record of 5 completions
      character.updateCompletionRecord('working', 5);
      final initialEndurance = character.stats.endurance;

      // Enable auto-repeat
      activityManager.autoRepeat = true;
      activityManager.startActivity(Activities.working, force: true);

      // Complete activity only 3 times (below record of 5)
      for (var i = 0; i < 20; i++) {
        tickerProvider.ticker!.advance(const Duration(milliseconds: 1000));
      }

      expect(activityManager.dailyCompletions['working'], equals(3));

      // Daily gains should be empty (3 < 5 record)
      expect(activityManager.dailyGains.isEmpty, isTrue);

      // Start a new day
      activityManager.startNewDay();

      // Stats should NOT have changed
      expect(character.stats.endurance, equals(initialEndurance));

      // Record should still be 5
      expect(character.getCompletionRecord('working'), equals(5));
    });

    test('should only gain stats for levels above record', () {
      // Set a pre-existing record of 2 completions
      character.updateCompletionRecord('working', 2);
      final initialEndurance = character.stats.endurance;

      // Enable auto-repeat
      activityManager.autoRepeat = true;
      activityManager.startActivity(Activities.working, force: true);

      // Complete activity 5 times (3 above record)
      // Each completion takes longer due to difficulty increase
      for (var i = 0; i < 40; i++) {
        tickerProvider.ticker!.advance(const Duration(milliseconds: 1000));
      }

      expect(activityManager.dailyCompletions['working'], equals(5));

      // Daily gains should be for 3 new levels (5 - 2 = 3)
      final workingRewards = Activities.working.rewards;
      final expectedEndurance = (workingRewards[StatType.endurance] ?? 0) * 3;
      expect(
        activityManager.dailyGains[StatType.endurance],
        closeTo(expectedEndurance, 0.001),
      );

      // Start a new day
      activityManager.startNewDay();

      // Stats should have increased by 3x the reward
      expect(
        character.stats.endurance,
        closeTo(initialEndurance + expectedEndurance, 0.001),
      );

      // Record should be updated to 5
      expect(character.getCompletionRecord('working'), equals(5));
    });

    test('should stop activity and trigger callback when day expires', () {
      // Start at 23:59 with very fast time multiplier
      final gameTime = GameTime(
        initialHour: 23,
        initialMinute: 59,
        timeMultiplier: 3000.0, // 10x faster
      );
      activityManager = ActivityManager(
        character: character,
        gameLoop: gameLoop,
        gameTime: gameTime,
      );

      bool dayExpiredCalled = false;
      Map<StatType, double>? receivedGains;

      activityManager.onDayExpired = (gains) {
        dayExpiredCalled = true;
        receivedGains = gains;
      };

      // Start an activity
      activityManager.startActivity(Activities.working, force: true);
      expect(activityManager.hasActiveActivity, isTrue);

      // Advance time to expire the day
      // 1 minute = 60 seconds, at 3000x that's 60/3000 = 0.02 real seconds = 20ms
      tickerProvider.ticker!.advance(const Duration(milliseconds: 100));

      // Day should be expired
      expect(gameTime.isExpired, isTrue);
      expect(dayExpiredCalled, isTrue);
      expect(receivedGains, isNotNull);
      // Activity should be stopped
      expect(activityManager.hasActiveActivity, isFalse);
    });

    test('should not process activities after day expires', () {
      // Create game time already expired
      final gameTime = GameTime(initialHour: 23, initialMinute: 59);
      gameTime.update(const Duration(milliseconds: 1000)); // Expire the day

      activityManager = ActivityManager(
        character: character,
        gameLoop: gameLoop,
        gameTime: gameTime,
      );

      // Try to start an activity
      activityManager.startActivity(Activities.working, force: true);

      // Advance time - should not process
      tickerProvider.ticker!.advance(const Duration(milliseconds: 5000));

      // No completions should be recorded
      expect(activityManager.dailyCompletions.isEmpty, isTrue);
    });
  });
}
