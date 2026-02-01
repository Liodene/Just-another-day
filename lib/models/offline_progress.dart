import '../utils/time_utils.dart';
import 'character.dart';
import 'game_time.dart';

/// Data class containing offline progress calculations and display information.
///
/// This class encapsulates all the information needed to display the offline
/// progress modal when a user returns to the game after being away.
class OfflineProgressData {
  /// Creates an [OfflineProgressData] instance.
  const OfflineProgressData({
    required this.realTimeElapsed,
    required this.gameTimeElapsed,
    required this.lastSavedAt,
    required this.currentTime,
    required this.dayCount,
    required this.currentStats,
  });

  /// The real-world time elapsed since last save.
  final Duration realTimeElapsed;

  /// The equivalent in-game time that would have passed.
  final Duration gameTimeElapsed;

  /// The timestamp when the game was last saved.
  final DateTime lastSavedAt;

  /// The current timestamp when offline progress was calculated.
  final DateTime currentTime;

  /// The current day count in the game.
  final int dayCount;

  /// The current character stats.
  final CharacterStats currentStats;

  /// Formats the real-world time elapsed in a human-readable format.
  ///
  /// Shows up to 2 most significant time units.
  /// Examples: "2 hours 15 minutes", "3 days 5 hours", "45 minutes"
  String get formattedRealTime {
    return formatDuration(realTimeElapsed);
  }

  /// Formats the game time equivalent in a human-readable format.
  ///
  /// Shows up to 2 most significant time units.
  /// Examples: "450 hours", "18 days 18 hours"
  String get formattedGameTime {
    return formatDuration(gameTimeElapsed);
  }

  /// Calculates offline progress data based on the saved timestamp.
  ///
  /// Returns `null` if the elapsed time is less than the threshold (5 minutes)
  /// or if the time delta is negative (clock went backwards).
  ///
  /// Parameters:
  /// - [savedAt]: The UTC timestamp when the game was last saved
  /// - [gameTime]: The current game time state
  /// - [character]: The current character state
  /// - [timeMultiplier]: The game time multiplier (default: 300.0)
  static OfflineProgressData? calculate(
    DateTime savedAt,
    GameTime gameTime,
    Character character, {
    double timeMultiplier = 300.0,
  }) {
    final now = DateTime.now().toUtc();
    final delta = now.difference(savedAt);

    // Check for negative delta (clock went backwards)
    if (delta.isNegative) {
      return null;
    }

    // Check if delta is below threshold (5 minutes = 300 seconds)
    const thresholdSeconds = 300;
    if (delta.inSeconds < thresholdSeconds) {
      return null;
    }

    // Calculate equivalent in-game time
    final gameTimeSeconds = delta.inSeconds * timeMultiplier;
    final gameTimeDuration = Duration(seconds: gameTimeSeconds.toInt());

    return OfflineProgressData(
      realTimeElapsed: delta,
      gameTimeElapsed: gameTimeDuration,
      lastSavedAt: savedAt,
      currentTime: now,
      dayCount: gameTime.dayCount,
      currentStats: character.stats,
    );
  }
}
