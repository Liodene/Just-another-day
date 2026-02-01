import 'package:flutter_test/flutter_test.dart';
import 'package:just_another_day/models/game_time.dart';

void main() {
  group('GameTime', () {
    test('should initialize with default values', () {
      final gameTime = GameTime();

      expect(gameTime.hour, equals(8));
      expect(gameTime.minute, equals(0));
      expect(gameTime.dayCount, equals(1));
      expect(gameTime.realTimePlayed, equals(Duration.zero));
      expect(gameTime.timeMultiplier, equals(300.0));
    });

    test('should initialize with custom start time', () {
      final gameTime = GameTime(initialHour: 12, initialMinute: 30);

      expect(gameTime.hour, equals(12));
      expect(gameTime.minute, equals(30));
    });

    test('should format time correctly', () {
      final gameTime = GameTime(initialHour: 8, initialMinute: 5);

      expect(gameTime.formattedTime, equals('08:05'));
    });

    test('should update in-game time at 300x speed', () {
      final gameTime = GameTime(initialHour: 8, initialMinute: 0);

      // 1 real second = 300 game seconds = 5 game minutes
      gameTime.update(const Duration(milliseconds: 1000)); // 1000ms = 1 second real time

      expect(gameTime.hour, equals(8));
      expect(gameTime.minute, equals(5));
    });

    test('should track real time played', () {
      final gameTime = GameTime();

      gameTime.update(const Duration(milliseconds: 1000)); // 1 second
      expect(gameTime.realTimePlayed, equals(const Duration(milliseconds: 1000)));
      expect(gameTime.realTimePlayed.inSeconds, equals(1));

      gameTime.update(const Duration(milliseconds: 59000)); // 59 more seconds
      expect(gameTime.realTimePlayed, equals(const Duration(milliseconds: 60000)));
      expect(gameTime.realTimePlayed.inMinutes, equals(1));
    });

    test('should stop at 24:00 instead of rolling over', () {
      // Start at 23:55
      final gameTime = GameTime(initialHour: 23, initialMinute: 55);
      expect(gameTime.dayCount, equals(1));
      expect(gameTime.isExpired, isFalse);

      // Advance 2 real seconds = 600 game seconds = 10 game minutes
      // 23:55 + 10 minutes would be 00:05, but should stop at 24:00
      gameTime.update(const Duration(milliseconds: 2000));

      expect(gameTime.dayCount, equals(1)); // Day doesn't change automatically
      expect(gameTime.isExpired, isTrue);
      expect(gameTime.hour, equals(24));
      expect(gameTime.minute, equals(0));
    });

    test('should not update time after day expires', () {
      // Start at 23:59
      final gameTime = GameTime(initialHour: 23, initialMinute: 59);

      // Advance to 24:00
      gameTime.update(const Duration(milliseconds: 1000)); // 5 game minutes

      expect(gameTime.isExpired, isTrue);
      final realTimeBeforeExpiry = gameTime.realTimePlayed;

      // Try to update more - should be ignored
      gameTime.update(const Duration(milliseconds: 10000));

      // Real time should not have been tracked after expiry
      expect(gameTime.realTimePlayed, equals(realTimeBeforeExpiry));
      expect(gameTime.isExpired, isTrue);
    });

    test('startNewDay should reset time and increment day count', () {
      // Start at 23:55 and expire
      final gameTime = GameTime(initialHour: 23, initialMinute: 55);
      gameTime.update(const Duration(milliseconds: 2000)); // Expire the day
      expect(gameTime.isExpired, isTrue);
      expect(gameTime.dayCount, equals(1));

      // Start a new day
      gameTime.startNewDay();

      expect(gameTime.isExpired, isFalse);
      expect(gameTime.dayCount, equals(2));
      expect(gameTime.hour, equals(8)); // Default initial hour
      expect(gameTime.minute, equals(0));
    });

    test('startNewDay with custom time should work', () {
      final gameTime = GameTime(initialHour: 23, initialMinute: 55);
      gameTime.update(const Duration(milliseconds: 2000)); // Expire
      expect(gameTime.isExpired, isTrue);

      gameTime.startNewDay(initialHour: 6, initialMinute: 30);

      expect(gameTime.isExpired, isFalse);
      expect(gameTime.hour, equals(6));
      expect(gameTime.minute, equals(30));
    });

    test('should reset correctly', () {
      final gameTime = GameTime();
      gameTime.update(const Duration(milliseconds: 10000));

      gameTime.reset(initialHour: 12, initialMinute: 0);

      expect(gameTime.hour, equals(12));
      expect(gameTime.minute, equals(0));
      expect(gameTime.dayCount, equals(1));
      expect(gameTime.realTimePlayed, equals(Duration.zero));
    });

    test('should work with custom time multiplier', () {
      // 1 real second = 60 game seconds = 1 game minute
      final gameTime = GameTime(timeMultiplier: 60.0, initialHour: 8);

      gameTime.update(const Duration(milliseconds: 1000)); // 1 real second

      expect(gameTime.hour, equals(8));
      expect(gameTime.minute, equals(1));
    });

    test('toString should return formatted string', () {
      final gameTime = GameTime(initialHour: 14, initialMinute: 30);

      expect(gameTime.toString(), equals('GameTime(Day 1, 14:30)'));
    });
  });
}
