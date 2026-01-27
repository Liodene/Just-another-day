import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_another_day/engine/activity_manager.dart';
import 'package:just_another_day/engine/game_loop.dart';
import 'package:just_another_day/models/activity.dart';
import 'package:just_another_day/models/character.dart';

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

  group('ActivityManager activity plan', () {
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

    test('should start with empty plan', () {
      expect(activityManager.activityPlan, isEmpty);
      expect(activityManager.hasPlan, isFalse);
    });

    test('should add activity to plan', () {
      activityManager.addToPlan(Activities.working);

      expect(activityManager.activityPlan.length, equals(1));
      expect(activityManager.activityPlan.first.id, equals('working'));
      expect(activityManager.hasPlan, isTrue);
    });

    test('should auto-start first activity when added to empty plan', () {
      activityManager.addToPlan(Activities.working);

      expect(activityManager.hasActiveActivity, isTrue);
      expect(activityManager.currentActivity!.id, equals('working'));
    });

    test('should not auto-start when activity already running', () {
      activityManager.startActivity(Activities.studying, force: true);
      activityManager.addToPlan(Activities.working);

      // Current activity should still be studying
      expect(activityManager.currentActivity!.id, equals('studying'));
    });

    test('should remove activity from plan by index', () {
      activityManager.addToPlan(Activities.working);
      activityManager.addToPlan(Activities.studying);

      final removed = activityManager.removeFromPlan(1);

      expect(removed!.id, equals('studying'));
      expect(activityManager.activityPlan.length, equals(1));
    });

    test('should cancel current and save progress when removing index 0', () {
      activityManager.addToPlan(Activities.working);

      // Advance to 50% progress
      tickerProvider.ticker!.advance(const Duration(milliseconds: 2500));
      expect(activityManager.currentProgress!.progress, closeTo(0.5, 0.01));

      // Remove from plan - should cancel and save
      activityManager.removeFromPlan(0);

      // Activity should be stopped
      expect(activityManager.hasActiveActivity, isFalse);
      // Progress should be saved
      expect(character.getSavedProgress('working'), closeTo(0.5, 0.01));
    });

    test('should move to next activity when removing current from plan', () {
      activityManager.addToPlan(Activities.working);
      activityManager.addToPlan(Activities.studying);

      // Advance to 50% progress on working
      tickerProvider.ticker!.advance(const Duration(milliseconds: 2500));

      // Remove current activity from plan
      activityManager.removeFromPlan(0);

      // Should now be doing studying
      expect(activityManager.currentActivity!.id, equals('studying'));
      // Working progress should be saved
      expect(character.getSavedProgress('working'), closeTo(0.5, 0.01));
    });

    test('should move to next activity in plan when activity completes', () {
      activityManager.addToPlan(Activities.working);
      activityManager.addToPlan(Activities.studying);

      // Working duration = 5 seconds, complete it
      tickerProvider.ticker!.advance(const Duration(milliseconds: 5000));

      // Should now be doing studying
      expect(activityManager.currentActivity!.id, equals('studying'));
      // Plan should only have studying now
      expect(activityManager.activityPlan.length, equals(1));
    });

    test('should clear plan and stop activity', () {
      activityManager.addToPlan(Activities.working);
      activityManager.addToPlan(Activities.studying);

      // Advance to 50% progress
      tickerProvider.ticker!.advance(const Duration(milliseconds: 2500));

      activityManager.clearPlan();

      expect(activityManager.activityPlan, isEmpty);
      expect(activityManager.hasActiveActivity, isFalse);
      // Progress should be saved
      expect(character.getSavedProgress('working'), closeTo(0.5, 0.01));
    });

    test('should reorder activities in plan', () {
      activityManager.addToPlan(Activities.working);
      activityManager.addToPlan(Activities.studying);
      activityManager.addToPlan(Activities.exercising);

      // Move studying to the end
      activityManager.reorderPlan(1, 3);

      expect(activityManager.activityPlan[0].id, equals('working'));
      expect(activityManager.activityPlan[1].id, equals('exercising'));
      expect(activityManager.activityPlan[2].id, equals('studying'));
    });

    test('should handle reordering current activity', () {
      activityManager.addToPlan(Activities.working);
      activityManager.addToPlan(Activities.studying);

      // Get some progress on working
      tickerProvider.ticker!.advance(const Duration(milliseconds: 2500));

      // Move working to position 1 (after studying)
      activityManager.reorderPlan(0, 2);

      // Studying should now be running
      expect(activityManager.currentActivity!.id, equals('studying'));
      // Working progress should be saved
      expect(character.getSavedProgress('working'), closeTo(0.5, 0.01));
    });

    test('should insert activity at specific position', () {
      activityManager.addToPlan(Activities.working);
      activityManager.addToPlan(Activities.studying);

      activityManager.insertIntoPlan(1, Activities.exercising);

      expect(activityManager.activityPlan[0].id, equals('working'));
      expect(activityManager.activityPlan[1].id, equals('exercising'));
      expect(activityManager.activityPlan[2].id, equals('studying'));
    });

    test('should remove activity by reference', () {
      activityManager.addToPlan(Activities.working);
      activityManager.addToPlan(Activities.studying);

      final result = activityManager.removeActivityFromPlan(Activities.studying);

      expect(result, isTrue);
      expect(activityManager.activityPlan.length, equals(1));
      expect(activityManager.activityPlan.first.id, equals('working'));
    });

    test('plan takes priority over auto-repeat', () {
      activityManager.autoRepeat = true;
      activityManager.addToPlan(Activities.working);
      activityManager.addToPlan(Activities.studying);

      // Complete working
      tickerProvider.ticker!.advance(const Duration(milliseconds: 5000));

      // Should move to studying from plan, not repeat working
      expect(activityManager.currentActivity!.id, equals('studying'));
    });

    test('auto-repeat works when plan is empty', () {
      activityManager.autoRepeat = true;
      activityManager.startActivity(Activities.working, force: true);

      // Complete working
      tickerProvider.ticker!.advance(const Duration(milliseconds: 5000));

      // Should repeat working since plan is empty
      expect(activityManager.currentActivity!.id, equals('working'));
      expect(activityManager.currentProgress!.progress, closeTo(0.0, 0.01));
    });
  });
}
