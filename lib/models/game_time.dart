/// Manages in-game time, day count, and real time tracking.
///
/// The in-game clock runs at [timeMultiplier] speed relative to real time.
/// By default, 1 real second = 300 in-game seconds (5 in-game minutes).
/// Time stops at 24:00 and must be manually reset via [startNewDay] to continue.
class GameTime {
  /// Creates a new [GameTime] instance.
  GameTime({
    this.timeMultiplier = 300.0,
    int initialHour = 8,
    int initialMinute = 0,
  })  : _inGameTime = Duration(
            seconds: initialHour * 3600 + initialMinute * 60,
          ),
        _dayCount = 1,
        _realTimePlayed = Duration.zero;

  /// Creates a [GameTime] instance with direct internal state.
  GameTime._internal({
    required this.timeMultiplier,
    required Duration inGameTime,
    required int dayCount,
    required Duration realTimePlayed,
  })  : _inGameTime = inGameTime,
        _dayCount = dayCount,
        _realTimePlayed = realTimePlayed;

  /// Creates a [GameTime] instance from a JSON map.
  factory GameTime.fromJson(Map<String, dynamic> json) {
    return GameTime._internal(
      timeMultiplier: (json['timeMultiplier'] as num?)?.toDouble() ?? 300.0,
      inGameTime: Duration(
        seconds: (json['inGameSeconds'] as num?)?.toInt() ?? 28800,
      ),
      dayCount: (json['dayCount'] as num?)?.toInt() ?? 1,
      realTimePlayed: Duration(
        milliseconds: (json['realTimePlayedMs'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  /// Converts this [GameTime] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'timeMultiplier': timeMultiplier,
      'inGameSeconds': _inGameTime.inSeconds,
      'dayCount': _dayCount,
      'realTimePlayedMs': _realTimePlayed.inMilliseconds,
    };
  }

  /// The multiplier for converting real time to in-game time.
  /// Default: 300 (1 real second = 300 in-game seconds = 5 in-game minutes).
  final double timeMultiplier;

  /// In-game time since midnight (0 to maxDayDuration).
  Duration _inGameTime;

  /// Number of days since game start.
  int _dayCount;

  /// Total real time played.
  Duration _realTimePlayed;

  /// The maximum duration in a day (24 hours).
  static const Duration maxDayDuration = Duration(hours: 24);

  /// Current in-game hour (0-24). Returns 24 when day is expired.
  int get hour => isExpired ? 24 : (_inGameTime.inSeconds ~/ 3600) % 24;

  /// Current in-game minute (0-59). Returns 0 when day is expired.
  int get minute => isExpired ? 0 : (_inGameTime.inSeconds ~/ 60) % 60;

  /// Current in-game second (0-59). Returns 0 when day is expired.
  int get second => isExpired ? 0 : _inGameTime.inSeconds % 60;

  /// Whether the day has expired (reached 24:00).
  bool get isExpired => _inGameTime >= maxDayDuration;

  /// Current day count since game start.
  int get dayCount => _dayCount;

  /// Total real time played.
  Duration get realTimePlayed => _realTimePlayed;

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
  /// [realDeltaTime] is the real time elapsed.
  /// Time will stop at 24:00 and will not roll over.
  /// Use [startNewDay] to advance to the next day.
  void update(Duration realDeltaTime) {
    // Don't update if day is already expired
    if (isExpired) return;

    // Track real time played
    _realTimePlayed += realDeltaTime;

    // Convert to in-game time
    final inGameDelta = Duration(
      microseconds: (realDeltaTime.inMicroseconds * timeMultiplier).round(),
    );
    _inGameTime += inGameDelta;

    // Cap at 24:00 instead of rolling over
    if (_inGameTime >= maxDayDuration) {
      _inGameTime = maxDayDuration;
    }
  }

  /// Starts a new day, resetting the time to the initial hour.
  ///
  /// This increments the day count and resets the in-game time.
  /// Should be called after the day end modal is dismissed.
  void startNewDay({int initialHour = 8, int initialMinute = 0}) {
    _inGameTime = Duration(
      seconds: initialHour * 3600 + initialMinute * 60,
    );
    _dayCount++;
  }

  /// Resets the game time to the initial state.
  void reset({int initialHour = 8, int initialMinute = 0}) {
    _inGameTime = Duration(
      seconds: initialHour * 3600 + initialMinute * 60,
    );
    _dayCount = 1;
    _realTimePlayed = Duration.zero;
  }

  /// Restores state from another GameTime instance (used when loading a save).
  void restoreFrom(GameTime other) {
    _inGameTime = other._inGameTime;
    _dayCount = other._dayCount;
    _realTimePlayed = other._realTimePlayed;
  }

  /// Gets the internal in-game time as a Duration.
  Duration get inGameTime => _inGameTime;

  /// Gets the internal in-game time in seconds (for compatibility).
  double get inGameSeconds => _inGameTime.inSeconds.toDouble();

  @override
  String toString() => 'GameTime(Day $_dayCount, $formattedTime)';
}
