/// Manages in-game time, day count, and real time tracking.
///
/// The in-game clock runs at [timeMultiplier] speed relative to real time.
/// By default, 1 real second = 300 in-game seconds (5 in-game minutes).
class GameTime {
  /// Creates a new [GameTime] instance.
  GameTime({
    this.timeMultiplier = 300.0,
    int initialHour = 8,
    int initialMinute = 0,
  })  : _inGameSeconds = (initialHour * 3600 + initialMinute * 60).toDouble(),
        _dayCount = 1,
        _realTimePlayedMs = 0.0;

  /// Creates a [GameTime] instance with direct internal state.
  GameTime._internal({
    required this.timeMultiplier,
    required double inGameSeconds,
    required int dayCount,
    required double realTimePlayedMs,
  })  : _inGameSeconds = inGameSeconds,
        _dayCount = dayCount,
        _realTimePlayedMs = realTimePlayedMs;

  /// Creates a [GameTime] instance from a JSON map.
  factory GameTime.fromJson(Map<String, dynamic> json) {
    return GameTime._internal(
      timeMultiplier: (json['timeMultiplier'] as num?)?.toDouble() ?? 300.0,
      inGameSeconds: (json['inGameSeconds'] as num?)?.toDouble() ?? 28800.0,
      dayCount: (json['dayCount'] as num?)?.toInt() ?? 1,
      realTimePlayedMs: (json['realTimePlayedMs'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Converts this [GameTime] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'timeMultiplier': timeMultiplier,
      'inGameSeconds': _inGameSeconds,
      'dayCount': _dayCount,
      'realTimePlayedMs': _realTimePlayedMs,
    };
  }

  /// The multiplier for converting real time to in-game time.
  /// Default: 300 (1 real second = 300 in-game seconds = 5 in-game minutes).
  final double timeMultiplier;

  /// In-game time in seconds since midnight (0-86400).
  double _inGameSeconds;

  /// Number of days since game start.
  int _dayCount;

  /// Total real time played in milliseconds (not displayed).
  double _realTimePlayedMs;

  /// Current in-game hour (0-23).
  int get hour => (_inGameSeconds ~/ 3600) % 24;

  /// Current in-game minute (0-59).
  int get minute => (_inGameSeconds ~/ 60).toInt() % 60;

  /// Current in-game second (0-59).
  int get second => _inGameSeconds.toInt() % 60;

  /// Current day count since game start.
  int get dayCount => _dayCount;

  /// Total real time played in milliseconds.
  double get realTimePlayedMs => _realTimePlayedMs;

  /// Total real time played in seconds.
  double get realTimePlayedSeconds => _realTimePlayedMs / 1000.0;

  /// Total real time played in minutes.
  double get realTimePlayedMinutes => _realTimePlayedMs / 60000.0;

  /// Total real time played in hours.
  double get realTimePlayedHours => _realTimePlayedMs / 3600000.0;

  /// Formatted in-game time string (HH:MM).
  String get formattedTime {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Formatted in-game time string with seconds (HH:MM:SS).
  String get formattedTimeWithSeconds {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    final s = second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  /// Updates the game time based on real time elapsed.
  ///
  /// [realDeltaTimeMs] is the real time elapsed in milliseconds.
  void update(double realDeltaTimeMs) {
    // Track real time played
    _realTimePlayedMs += realDeltaTimeMs;

    // Convert to in-game time
    final inGameDeltaSeconds = (realDeltaTimeMs / 1000.0) * timeMultiplier;
    _inGameSeconds += inGameDeltaSeconds;

    // Handle day rollover
    while (_inGameSeconds >= 86400) {
      _inGameSeconds -= 86400;
      _dayCount++;
    }
  }

  /// Resets the game time to the initial state.
  void reset({int initialHour = 8, int initialMinute = 0}) {
    _inGameSeconds = (initialHour * 3600 + initialMinute * 60).toDouble();
    _dayCount = 1;
    _realTimePlayedMs = 0.0;
  }

  /// Restores state from another GameTime instance (used when loading a save).
  void restoreFrom(GameTime other) {
    _inGameSeconds = other._inGameSeconds;
    _dayCount = other._dayCount;
    _realTimePlayedMs = other._realTimePlayedMs;
  }

  /// Gets the internal in-game seconds value.
  double get inGameSeconds => _inGameSeconds;

  @override
  String toString() => 'GameTime(Day $_dayCount, $formattedTime)';
}
