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
      final started = activityManager.startActivity(
        Activities.working,
        force: true,
      );
      expect(started, isTrue);
      expect(activityManager.currentProgress, isNotNull);

      // Manually set elapsed time to simulate 50% progress
      // Working duration: 10 * (5/1) = 50 seconds, so 50% = 25 seconds
      activityManager.currentProgress!.elapsedTime = 25.0;

      expect(activityManager.currentProgress!.progress, closeTo(0.5, 0.01));

      // Now switch to studying - should save working progress
      activityManager.startActivity(Activities.studying, force: true);

      // Check that working progress was saved
      expect(character.getSavedProgress('working'), closeTo(0.5, 0.01));

      // Current activity should now be studying
      expect(activityManager.currentActivity, isNotNull);
      expect(activityManager.currentActivity!.id, equals('studying'));
    });

    test('should restore saved progress when returning to activity', () {
      // Start working and get some progress
      final started = activityManager.startActivity(
        Activities.working,
        force: true,
      );
      expect(started, isTrue);
      expect(activityManager.currentProgress, isNotNull);

      // Manually set elapsed time to simulate 50% progress
      activityManager.currentProgress!.elapsedTime = 25.0;
      expect(activityManager.currentProgress!.progress, closeTo(0.5, 0.01));

      // Switch to studying
      activityManager.startActivity(Activities.studying, force: true);
      expect(character.getSavedProgress('working'), closeTo(0.5, 0.01));

      // Switch back to working - should restore progress
      activityManager.startActivity(Activities.working, force: true);
      expect(activityManager.currentProgress, isNotNull);

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
      final started = activityManager.startActivity(
        Activities.working,
        force: true,
      );
      expect(started, isTrue);
      expect(activityManager.currentProgress, isNotNull);

      // Manually set elapsed time to simulate 30% progress (15 seconds of 50)
      activityManager.currentProgress!.elapsedTime = 15.0;
      expect(activityManager.currentProgress!.progress, closeTo(0.3, 0.01));

      // Stop activity - should save progress by default
      activityManager.stopActivity();

      // Check that progress was saved
      expect(character.getSavedProgress('working'), closeTo(0.3, 0.01));
    });

    test('should not save progress when stopping with grantPartialRewards', () {
      // Start working activity
      activityManager.startActivity(Activities.working, force: true);
      expect(activityManager.currentProgress, isNotNull);

      // Manually set elapsed time to simulate 30% progress
      activityManager.currentProgress!.elapsedTime = 15.0;

      // Stop activity with partial rewards (don't save progress)
      activityManager.stopActivity(grantPartialRewards: true);

      // Progress should NOT be saved when granting partial rewards
      expect(character.getSavedProgress('working'), equals(0.0));
    });

    test('should not save progress when stopping with saveProgress=false', () {
      // Start working activity
      activityManager.startActivity(Activities.working, force: true);
      expect(activityManager.currentProgress, isNotNull);

      // Manually set elapsed time to simulate 30% progress
      activityManager.currentProgress!.elapsedTime = 15.0;

      // Stop activity without saving progress
      activityManager.stopActivity(saveProgress: false);

      // Progress should NOT be saved
      expect(character.getSavedProgress('working'), equals(0.0));
    });

    test('should not save progress when switching to same activity', () {
      // Start working activity
      final started = activityManager.startActivity(
        Activities.working,
        force: true,
      );
      expect(started, isTrue);
      expect(activityManager.currentProgress, isNotNull);

      // Manually set elapsed time to simulate 50% progress
      activityManager.currentProgress!.elapsedTime = 25.0;
      final initialProgress = activityManager.currentProgress!.progress;

      // Try to start the same activity without force - should fail
      final result = activityManager.startActivity(Activities.working);
      expect(result, isFalse); // Can't start - already running

      // Progress should remain unchanged
      expect(activityManager.currentProgress, isNotNull);
      expect(
        activityManager.currentProgress!.progress,
        closeTo(initialProgress, 0.01),
      );
    });

    test('partial progress should persist through save/restore', () {
      // Start working and get progress
      activityManager.startActivity(Activities.working, force: true);
      expect(activityManager.currentProgress, isNotNull);

      // Manually set elapsed time to simulate 50% progress
      activityManager.currentProgress!.elapsedTime = 25.0;

      // Switch to studying to save working progress
      activityManager.startActivity(Activities.studying, force: true);

      // Simulate save/restore cycle
      final savedJson = character.toJson();
      final restoredCharacter = Character.fromJson(savedJson);

      // Verify progress was preserved
      expect(restoredCharacter.getSavedProgress('working'), closeTo(0.5, 0.01));
    });

    test('multiple activities should track progress independently', () {
      // Start working and get 50% progress
      activityManager.startActivity(Activities.working, force: true);
      expect(activityManager.currentProgress, isNotNull);

      // Manually set elapsed time to simulate 50% progress (25 of 50 seconds)
      activityManager.currentProgress!.elapsedTime = 25.0;

      // Switch to studying
      activityManager.startActivity(Activities.studying, force: true);
      expect(activityManager.currentProgress, isNotNull);

      // Get 30% progress on studying
      // Studying: baseDuration=15, difficulty=8, primary=intelligence
      // With intelligence=1: duration = 15 * (8/1) = 120 seconds
      // For 30% progress: need 36 seconds
      activityManager.currentProgress!.elapsedTime = 36.0;

      // Switch to exercising
      activityManager.startActivity(Activities.exercising, force: true);

      // Both working and studying should have saved progress
      expect(character.getSavedProgress('working'), closeTo(0.5, 0.01));
      expect(character.getSavedProgress('studying'), closeTo(0.3, 0.01));
    });
  });
}
