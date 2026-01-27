import 'package:flutter_test/flutter_test.dart';
import 'package:just_another_day/models/game_time.dart';

void main() {
  group('GameTime', () {
    test('should initialize with default values', () {
      final gameTime = GameTime();

      expect(gameTime.hour, equals(8));
      expect(gameTime.minute, equals(0));
      expect(gameTime.dayCount, equals(1));
      expect(gameTime.realTimePlayedMs, equals(0.0));
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
      gameTime.update(1000); // 1000ms = 1 second real time

      expect(gameTime.hour, equals(8));
      expect(gameTime.minute, equals(5));
    });

    test('should track real time played', () {
      final gameTime = GameTime();

      gameTime.update(1000); // 1 second
      expect(gameTime.realTimePlayedMs, equals(1000.0));
      expect(gameTime.realTimePlayedSeconds, equals(1.0));

      gameTime.update(59000); // 59 more seconds
      expect(gameTime.realTimePlayedMs, equals(60000.0));
      expect(gameTime.realTimePlayedMinutes, equals(1.0));
    });

    test('should handle day rollover', () {
      // Start at 23:55
      final gameTime = GameTime(initialHour: 23, initialMinute: 55);
      expect(gameTime.dayCount, equals(1));

      // Advance 2 real seconds = 600 game seconds = 10 game minutes
      // 23:55 + 10 minutes = 00:05 next day
      gameTime.update(2000);

      expect(gameTime.dayCount, equals(2));
      expect(gameTime.hour, equals(0));
      expect(gameTime.minute, equals(5));
    });

    test('should handle multiple day rollovers', () {
      final gameTime = GameTime(initialHour: 0, initialMinute: 0);

      // 1 game day = 86400 game seconds
      // At 300x, 1 game day = 288 real seconds
      // Advance 576 real seconds = 2 game days
      gameTime.update(576000); // 576 seconds in ms

      expect(gameTime.dayCount, equals(3)); // Started at day 1, +2 days
    });

    test('should reset correctly', () {
      final gameTime = GameTime();
      gameTime.update(10000);

      gameTime.reset(initialHour: 12, initialMinute: 0);

      expect(gameTime.hour, equals(12));
      expect(gameTime.minute, equals(0));
      expect(gameTime.dayCount, equals(1));
      expect(gameTime.realTimePlayedMs, equals(0.0));
    });

    test('should work with custom time multiplier', () {
      // 1 real second = 60 game seconds = 1 game minute
      final gameTime = GameTime(timeMultiplier: 60.0, initialHour: 8);

      gameTime.update(1000); // 1 real second

      expect(gameTime.hour, equals(8));
      expect(gameTime.minute, equals(1));
    });

    test('toString should return formatted string', () {
      final gameTime = GameTime(initialHour: 14, initialMinute: 30);

      expect(gameTime.toString(), equals('GameTime(Day 1, 14:30)'));
    });
  });
}
