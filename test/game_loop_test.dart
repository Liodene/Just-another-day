import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_another_day/engine/game_loop.dart';

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
  group('GameLoop', () {
    late FakeTickerProvider tickerProvider;
    late GameLoop gameLoop;

    setUp(() {
      tickerProvider = FakeTickerProvider();
      gameLoop = GameLoop(vsync: tickerProvider);
    });

    tearDown(() {
      gameLoop.dispose();
    });

    test('should not be running initially', () {
      expect(gameLoop.isRunning, isFalse);
    });

    test('should start and stop correctly', () {
      gameLoop.start();
      expect(gameLoop.isRunning, isTrue);

      gameLoop.stop();
      expect(gameLoop.isRunning, isFalse);
    });

    test('should not start twice', () {
      gameLoop.start();
      final ticker1 = tickerProvider.ticker;

      gameLoop.start();
      final ticker2 = tickerProvider.ticker;

      // Same ticker should be used
      expect(ticker1, equals(ticker2));
    });

    test('should call callbacks with delta time', () {
      final deltaTimes = <double>[];
      gameLoop.addCallback((dt) => deltaTimes.add(dt));
      gameLoop.start();

      // First tick at 16ms
      tickerProvider.ticker!.advance(const Duration(milliseconds: 16));
      expect(deltaTimes.length, equals(1));
      expect(deltaTimes[0], closeTo(0.016, 0.001));

      // Second tick at 32ms (16ms delta)
      tickerProvider.ticker!.advance(const Duration(milliseconds: 16));
      expect(deltaTimes.length, equals(2));
      expect(deltaTimes[1], closeTo(0.016, 0.001));
    });

    test('should support multiple callbacks', () {
      var callback1Called = false;
      var callback2Called = false;

      gameLoop.addCallback((_) => callback1Called = true);
      gameLoop.addCallback((_) => callback2Called = true);
      gameLoop.start();

      tickerProvider.ticker!.advance(const Duration(milliseconds: 16));

      expect(callback1Called, isTrue);
      expect(callback2Called, isTrue);
    });

    test('should remove callbacks', () {
      var callCount = 0;
      void callback(double dt) => callCount++;

      gameLoop.addCallback(callback);
      gameLoop.start();

      tickerProvider.ticker!.advance(const Duration(milliseconds: 16));
      expect(callCount, equals(1));

      gameLoop.removeCallback(callback);
      tickerProvider.ticker!.advance(const Duration(milliseconds: 16));
      expect(callCount, equals(1)); // Should not increment
    });

    test('addCallback should return removal function', () {
      var callCount = 0;
      final remove = gameLoop.addCallback((_) => callCount++);
      gameLoop.start();

      tickerProvider.ticker!.advance(const Duration(milliseconds: 16));
      expect(callCount, equals(1));

      remove();
      tickerProvider.ticker!.advance(const Duration(milliseconds: 16));
      expect(callCount, equals(1)); // Should not increment
    });

    test('should pause and resume', () {
      var callCount = 0;
      gameLoop.addCallback((_) => callCount++);
      gameLoop.start();

      tickerProvider.ticker!.advance(const Duration(milliseconds: 16));
      expect(callCount, equals(1));

      gameLoop.pause();
      expect(gameLoop.isPaused, isTrue);

      tickerProvider.ticker!.advance(const Duration(milliseconds: 16));
      expect(callCount, equals(1)); // Should not increment while paused

      gameLoop.resume();
      expect(gameLoop.isPaused, isFalse);

      tickerProvider.ticker!.advance(const Duration(milliseconds: 16));
      expect(callCount, equals(2)); // Should increment after resume
    });

    test('should track callback count', () {
      expect(gameLoop.callbackCount, equals(0));

      final remove1 = gameLoop.addCallback((_) {});
      expect(gameLoop.callbackCount, equals(1));

      gameLoop.addCallback((_) {});
      expect(gameLoop.callbackCount, equals(2));

      remove1();
      expect(gameLoop.callbackCount, equals(1));
    });

    test('dispose should clear callbacks and stop', () {
      gameLoop.addCallback((_) {});
      gameLoop.addCallback((_) {});
      gameLoop.start();

      gameLoop.dispose();

      expect(gameLoop.isRunning, isFalse);
      expect(gameLoop.callbackCount, equals(0));
    });
  });
}
