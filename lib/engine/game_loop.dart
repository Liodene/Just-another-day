import 'package:flutter/scheduler.dart';

/// Callback function type for game loop updates.
/// [deltaTime] is the time elapsed since the last frame in milliseconds.
typedef GameLoopCallback = void Function(double deltaTime);

/// A game loop engine based on Flutter's [Ticker].
///
/// This engine provides a consistent game loop that runs at the display's
/// refresh rate and calls registered callbacks with the delta time between
/// frames.
///
/// Usage:
/// ```dart
/// final gameLoop = GameLoop();
/// gameLoop.addCallback((deltaTime) {
///   // Update game state
/// });
/// gameLoop.start();
/// ```
class GameLoop {
  /// Creates a new [GameLoop] instance.
  ///
  /// The [vsync] parameter must be provided and should be a
  /// [TickerProvider] (typically a [State] that mixes in
  /// [SingleTickerProviderStateMixin] or [TickerProviderStateMixin]).
  GameLoop({required TickerProvider vsync}) : _vsync = vsync;

  final TickerProvider _vsync;
  Ticker? _ticker;
  Duration _lastElapsed = Duration.zero;
  final List<GameLoopCallback> _callbacks = [];
  bool _isRunning = false;

  /// Whether the game loop is currently running.
  bool get isRunning => _isRunning;

  /// The number of registered callbacks.
  int get callbackCount => _callbacks.length;

  /// Adds a callback to be called on each frame.
  ///
  /// The callback receives the delta time in milliseconds since the last frame.
  /// Returns a function that can be called to remove the callback.
  VoidCallback addCallback(GameLoopCallback callback) {
    _callbacks.add(callback);
    return () => removeCallback(callback);
  }

  /// Removes a previously added callback.
  ///
  /// Returns true if the callback was found and removed, false otherwise.
  bool removeCallback(GameLoopCallback callback) {
    return _callbacks.remove(callback);
  }

  /// Starts the game loop.
  ///
  /// If the game loop is already running, this method does nothing.
  void start() {
    if (_isRunning) return;

    _isRunning = true;
    _lastElapsed = Duration.zero;
    _ticker = _vsync.createTicker(_onTick);
    _ticker!.start();
  }

  /// Stops the game loop.
  ///
  /// If the game loop is not running, this method does nothing.
  void stop() {
    if (!_isRunning) return;

    _isRunning = false;
    _ticker?.stop();
    _ticker?.dispose();
    _ticker = null;
  }

  /// Pauses the game loop.
  ///
  /// Unlike [stop], this preserves the ticker state and can be resumed
  /// with [resume].
  void pause() {
    if (!_isRunning) return;
    _ticker?.muted = true;
  }

  /// Resumes a paused game loop.
  void resume() {
    if (!_isRunning) return;
    _ticker?.muted = false;
  }

  /// Whether the game loop is currently paused.
  bool get isPaused => _ticker?.muted ?? false;

  /// Disposes of the game loop and releases resources.
  ///
  /// After calling this method, the game loop cannot be started again.
  void dispose() {
    stop();
    _callbacks.clear();
  }

  void _onTick(Duration elapsed) {
    // Calculate delta time in milliseconds
    final deltaTime = (elapsed - _lastElapsed).inMicroseconds / 1000.0;
    _lastElapsed = elapsed;

    // Call all registered callbacks
    // Create a copy to allow callbacks to modify the list
    final callbacksCopy = List<GameLoopCallback>.from(_callbacks);
    for (final callback in callbacksCopy) {
      callback(deltaTime);
    }
  }
}
