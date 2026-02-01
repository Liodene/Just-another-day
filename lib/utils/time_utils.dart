/// Utility functions for formatting time durations.
library;

/// Formats a duration into a human-readable string.
///
/// Shows up to 2 most significant time units.
/// Examples:
/// - "2 hours, 15 minutes"
/// - "3 days, 5 hours"
/// - "45 minutes"
String formatDuration(Duration duration) {
  final days = duration.inDays;
  final hours = duration.inHours % 24;
  final minutes = duration.inMinutes % 60;

  // Show 2 most significant units
  if (days > 0) {
    if (hours > 0) {
      return '$days ${_pluralize('day', days)}, $hours ${_pluralize('hour', hours)}';
    }
    return '$days ${_pluralize('day', days)}';
  }

  if (hours > 0) {
    if (minutes > 0) {
      return '$hours ${_pluralize('hour', hours)}, $minutes ${_pluralize('minute', minutes)}';
    }
    return '$hours ${_pluralize('hour', hours)}';
  }

  return '$minutes ${_pluralize('minute', minutes)}';
}

/// Formats a Duration into a compact human-readable string.
///
/// Uses abbreviated units (h, m, s) and shows up to 2 units.
/// Examples:
/// - "2h 15m" (for 2 hours 15 minutes)
/// - "45m 30s" (for 45 minutes 30 seconds)
/// - "15s" (for 15 seconds)
String formatDurationCompact(Duration duration) {
  final totalSeconds = duration.inSeconds;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final secs = totalSeconds % 60;

  if (hours > 0) {
    return '${hours}h ${minutes}m';
  } else if (minutes > 0) {
    return '${minutes}m ${secs}s';
  } else {
    return '${secs}s';
  }
}

/// Helper to pluralize time units.
String _pluralize(String unit, int count) {
  return count == 1 ? unit : '${unit}s';
}
