import 'package:flutter_test/flutter_test.dart';
import 'package:just_another_day/engine/save_manager.dart';
import 'package:just_another_day/models/character.dart';
import 'package:just_another_day/models/game_time.dart';

void main() {
  group('CharacterStats JSON Serialization', () {
    test('toJson should serialize all stats', () {
      final stats = CharacterStats(
        strength: 5.0,
        intelligence: 10.0,
        endurance: 3.0,
        charisma: 7.0,
        agility: 2.0,
      );

      final json = stats.toJson();

      expect(json['strength'], equals(5.0));
      expect(json['intelligence'], equals(10.0));
      expect(json['endurance'], equals(3.0));
      expect(json['charisma'], equals(7.0));
      expect(json['agility'], equals(2.0));
    });

    test('fromJson should deserialize all stats', () {
      final json = {
        'strength': 5.0,
        'intelligence': 10.0,
        'endurance': 3.0,
        'charisma': 7.0,
        'agility': 2.0,
      };

      final stats = CharacterStats.fromJson(json);

      expect(stats.strength, equals(5.0));
      expect(stats.intelligence, equals(10.0));
      expect(stats.endurance, equals(3.0));
      expect(stats.charisma, equals(7.0));
      expect(stats.agility, equals(2.0));
    });

    test('fromJson should use defaults for missing values', () {
      final json = <String, dynamic>{};

      final stats = CharacterStats.fromJson(json);

      expect(stats.strength, equals(1.0));
      expect(stats.intelligence, equals(1.0));
      expect(stats.endurance, equals(1.0));
      expect(stats.charisma, equals(1.0));
      expect(stats.agility, equals(1.0));
    });

    test('round trip should preserve values', () {
      final original = CharacterStats(
        strength: 5.5,
        intelligence: 10.25,
        endurance: 3.1,
        charisma: 7.8,
        agility: 2.9,
      );

      final restored = CharacterStats.fromJson(original.toJson());

      expect(restored.strength, equals(original.strength));
      expect(restored.intelligence, equals(original.intelligence));
      expect(restored.endurance, equals(original.endurance));
      expect(restored.charisma, equals(original.charisma));
      expect(restored.agility, equals(original.agility));
    });
  });

  group('Character JSON Serialization', () {
    test('toJson should serialize character with stats and completions', () {
      final character = Character(
        name: 'TestPlayer',
        stats: CharacterStats(strength: 5.0, intelligence: 10.0),
        activityCompletions: {'working': 5, 'studying': 3},
      );

      final json = character.toJson();

      expect(json['name'], equals('TestPlayer'));
      expect(json['stats']['strength'], equals(5.0));
      expect(json['stats']['intelligence'], equals(10.0));
      expect(json['activityCompletions']['working'], equals(5));
      expect(json['activityCompletions']['studying'], equals(3));
    });

    test('fromJson should deserialize character', () {
      final json = {
        'name': 'TestPlayer',
        'stats': {
          'strength': 5.0,
          'intelligence': 10.0,
          'endurance': 1.0,
          'charisma': 1.0,
          'agility': 1.0,
        },
        'activityCompletions': {'working': 5, 'studying': 3},
      };

      final character = Character.fromJson(json);

      expect(character.name, equals('TestPlayer'));
      expect(character.stats.strength, equals(5.0));
      expect(character.stats.intelligence, equals(10.0));
      expect(character.getCompletions('working'), equals(5));
      expect(character.getCompletions('studying'), equals(3));
      expect(character.totalCompletions, equals(8));
    });

    test('fromJson should use defaults for missing values', () {
      final json = <String, dynamic>{};

      final character = Character.fromJson(json);

      expect(character.name, equals('Player'));
      expect(character.stats.strength, equals(1.0));
      expect(character.totalCompletions, equals(0));
    });

    test('round trip should preserve values', () {
      final original = Character(
        name: 'TestPlayer',
        stats: CharacterStats(strength: 5.5, intelligence: 10.25),
        activityCompletions: {'working': 10, 'studying': 5},
      );

      final restored = Character.fromJson(original.toJson());

      expect(restored.name, equals(original.name));
      expect(restored.stats.strength, equals(original.stats.strength));
      expect(restored.stats.intelligence, equals(original.stats.intelligence));
      expect(
        restored.getCompletions('working'),
        equals(original.getCompletions('working')),
      );
      expect(
        restored.getCompletions('studying'),
        equals(original.getCompletions('studying')),
      );
    });

    test('toJson should include saved activity progress', () {
      final character = Character(
        name: 'TestPlayer',
        savedActivityProgress: {'working': 0.5, 'studying': 0.75},
      );

      final json = character.toJson();

      expect(json['savedActivityProgress']['working'], equals(0.5));
      expect(json['savedActivityProgress']['studying'], equals(0.75));
    });

    test('fromJson should deserialize saved activity progress', () {
      final json = {
        'name': 'TestPlayer',
        'stats': {
          'strength': 1.0,
          'intelligence': 1.0,
          'endurance': 1.0,
          'charisma': 1.0,
          'agility': 1.0,
        },
        'activityCompletions': <String, int>{},
        'savedActivityProgress': {'working': 0.5, 'exercising': 0.3},
      };

      final character = Character.fromJson(json);

      expect(character.getSavedProgress('working'), equals(0.5));
      expect(character.getSavedProgress('exercising'), equals(0.3));
      expect(character.getSavedProgress('studying'), equals(0.0));
    });

    test('fromJson handles missing savedActivityProgress', () {
      final json = {
        'name': 'TestPlayer',
        'stats': {
          'strength': 1.0,
          'intelligence': 1.0,
          'endurance': 1.0,
          'charisma': 1.0,
          'agility': 1.0,
        },
        'activityCompletions': <String, int>{},
      };

      final character = Character.fromJson(json);

      expect(character.getSavedProgress('working'), equals(0.0));
      expect(character.savedActivityProgress, isEmpty);
    });

    test('round trip preserves saved activity progress', () {
      final original = Character(
        name: 'TestPlayer',
        savedActivityProgress: {'working': 0.5, 'studying': 0.75},
      );

      final restored = Character.fromJson(original.toJson());

      expect(
        restored.getSavedProgress('working'),
        equals(original.getSavedProgress('working')),
      );
      expect(
        restored.getSavedProgress('studying'),
        equals(original.getSavedProgress('studying')),
      );
    });
  });

  group('Character restoreFrom', () {
    test('should restore stats from another character', () {
      final target = Character(name: 'Target');
      final source = Character(
        name: 'Source',
        stats: CharacterStats(
          strength: 10.0,
          intelligence: 15.0,
          endurance: 5.0,
        ),
        activityCompletions: {'working': 5, 'studying': 3},
      );

      target.restoreFrom(source);

      expect(target.stats.strength, equals(10.0));
      expect(target.stats.intelligence, equals(15.0));
      expect(target.stats.endurance, equals(5.0));
      expect(target.getCompletions('working'), equals(5));
      expect(target.getCompletions('studying'), equals(3));
    });

    test('should clear previous completions before restoring', () {
      final target = Character(
        name: 'Target',
        activityCompletions: {'exercising': 10},
      );
      final source = Character(
        name: 'Source',
        activityCompletions: {'working': 5},
      );

      target.restoreFrom(source);

      expect(target.getCompletions('exercising'), equals(0));
      expect(target.getCompletions('working'), equals(5));
    });

    test('should restore saved activity progress', () {
      final target = Character(name: 'Target');
      final source = Character(
        name: 'Source',
        savedActivityProgress: {'working': 0.5, 'studying': 0.3},
      );

      target.restoreFrom(source);

      expect(target.getSavedProgress('working'), equals(0.5));
      expect(target.getSavedProgress('studying'), equals(0.3));
    });

    test('should clear previous saved progress before restoring', () {
      final target = Character(
        name: 'Target',
        savedActivityProgress: {'exercising': 0.75},
      );
      final source = Character(
        name: 'Source',
        savedActivityProgress: {'working': 0.5},
      );

      target.restoreFrom(source);

      expect(target.getSavedProgress('exercising'), equals(0.0));
      expect(target.getSavedProgress('working'), equals(0.5));
    });
  });

  group('GameTime JSON Serialization', () {
    test('toJson should serialize all game time data', () {
      final gameTime = GameTime(initialHour: 14, initialMinute: 30);
      gameTime.update(1000); // Add some time

      final json = gameTime.toJson();

      expect(json['timeMultiplier'], equals(300.0));
      expect(json['dayCount'], equals(1));
      expect(json['realTimePlayedMs'], equals(1000.0));
      expect(json.containsKey('inGameSeconds'), isTrue);
    });

    test('fromJson should deserialize game time', () {
      final json = {
        'timeMultiplier': 300.0,
        'inGameSeconds': 52200.0, // 14:30
        'dayCount': 5,
        'realTimePlayedMs': 60000.0,
      };

      final gameTime = GameTime.fromJson(json);

      expect(gameTime.timeMultiplier, equals(300.0));
      expect(gameTime.dayCount, equals(5));
      expect(gameTime.realTimePlayedMs, equals(60000.0));
      expect(gameTime.hour, equals(14));
      expect(gameTime.minute, equals(30));
    });

    test('fromJson should use defaults for missing values', () {
      final json = <String, dynamic>{};

      final gameTime = GameTime.fromJson(json);

      expect(gameTime.timeMultiplier, equals(300.0));
      expect(gameTime.dayCount, equals(1));
      expect(gameTime.hour, equals(8)); // Default hour from 28800 seconds
    });

    test('round trip should preserve values', () {
      final original = GameTime(initialHour: 18, initialMinute: 45);
      original.update(5000);

      final restored = GameTime.fromJson(original.toJson());

      expect(restored.dayCount, equals(original.dayCount));
      expect(restored.realTimePlayedMs, equals(original.realTimePlayedMs));
      expect(restored.hour, equals(original.hour));
      expect(restored.minute, equals(original.minute));
    });
  });

  group('GameTime restoreFrom', () {
    test('should restore state from another game time', () {
      final target = GameTime();
      final source = GameTime(initialHour: 18, initialMinute: 30);
      source.update(10000);

      target.restoreFrom(source);

      expect(target.hour, equals(source.hour));
      expect(target.minute, equals(source.minute));
      expect(target.dayCount, equals(source.dayCount));
      expect(target.realTimePlayedMs, equals(source.realTimePlayedMs));
    });
  });

  group('GameSaveData', () {
    test('should create save data with all fields', () {
      final character = Character(name: 'TestPlayer');
      final gameTime = GameTime();
      final savedAt = DateTime.now();

      final saveData = GameSaveData(
        character: character,
        gameTime: gameTime,
        savedAt: savedAt,
        timezone: 'UTC+02:00',
      );

      expect(saveData.character, equals(character));
      expect(saveData.gameTime, equals(gameTime));
      expect(saveData.savedAt, equals(savedAt));
      expect(saveData.timezone, equals('UTC+02:00'));
      expect(saveData.version, equals(1));
    });

    test('toJson should serialize all save data', () {
      final character = Character(
        name: 'TestPlayer',
        stats: CharacterStats(strength: 5.0),
        activityCompletions: {'working': 3},
      );
      final gameTime = GameTime(initialHour: 14, initialMinute: 30);
      final savedAt = DateTime(2026, 1, 27, 12, 30, 45);

      final saveData = GameSaveData(
        character: character,
        gameTime: gameTime,
        savedAt: savedAt,
        timezone: 'UTC+02:00',
      );

      final json = saveData.toJson();

      expect(json['version'], equals(1));
      expect(json['savedAt'], equals('2026-01-27T12:30:45.000'));
      expect(json['timezone'], equals('UTC+02:00'));
      expect(json['character']['name'], equals('TestPlayer'));
      expect(json['character']['stats']['strength'], equals(5.0));
      expect(json['gameTime']['inGameSeconds'], isNotNull);
    });

    test('fromJson should deserialize save data', () {
      final json = {
        'version': 1,
        'savedAt': '2026-01-27T12:30:45.000',
        'timezone': 'UTC+02:00',
        'character': {
          'name': 'TestPlayer',
          'stats': {
            'strength': 5.0,
            'intelligence': 1.0,
            'endurance': 1.0,
            'charisma': 1.0,
            'agility': 1.0,
          },
          'activityCompletions': {'working': 3},
        },
        'gameTime': {
          'timeMultiplier': 300.0,
          'inGameSeconds': 52200.0,
          'dayCount': 5,
          'realTimePlayedMs': 60000.0,
        },
      };

      final saveData = GameSaveData.fromJson(json);

      expect(saveData.version, equals(1));
      expect(saveData.savedAt, equals(DateTime(2026, 1, 27, 12, 30, 45)));
      expect(saveData.timezone, equals('UTC+02:00'));
      expect(saveData.character.name, equals('TestPlayer'));
      expect(saveData.character.stats.strength, equals(5.0));
      expect(saveData.character.getCompletions('working'), equals(3));
      expect(saveData.gameTime.dayCount, equals(5));
      expect(saveData.gameTime.hour, equals(14));
    });

    test('toJsonString should return valid JSON string', () {
      final character = Character(name: 'TestPlayer');
      final gameTime = GameTime();
      final savedAt = DateTime(2026, 1, 27, 12, 30, 45);

      final saveData = GameSaveData(
        character: character,
        gameTime: gameTime,
        savedAt: savedAt,
        timezone: 'UTC+00:00',
      );

      final jsonString = saveData.toJsonString();

      expect(jsonString, contains('"name":"TestPlayer"'));
      expect(jsonString, contains('"savedAt":"2026-01-27T12:30:45.000"'));
      expect(jsonString, contains('"timezone":"UTC+00:00"'));
    });

    test('fromJsonString should parse valid JSON string', () {
      const jsonString = '''
        {
          "version": 1,
          "savedAt": "2026-01-27T12:30:45.000",
          "timezone": "UTC+00:00",
          "character": {
            "name": "TestPlayer",
            "stats": {
              "strength": 5.0,
              "intelligence": 1.0,
              "endurance": 1.0,
              "charisma": 1.0,
              "agility": 1.0
            },
            "activityCompletions": {}
          },
          "gameTime": {
            "timeMultiplier": 300.0,
            "inGameSeconds": 28800.0,
            "dayCount": 1,
            "realTimePlayedMs": 0.0
          }
        }
      ''';

      final saveData = GameSaveData.fromJsonString(jsonString);

      expect(saveData, isNotNull);
      expect(saveData!.character.name, equals('TestPlayer'));
      expect(saveData.timezone, equals('UTC+00:00'));
    });

    test('fromJsonString should return null for invalid JSON', () {
      const invalidJson = 'not valid json';

      final saveData = GameSaveData.fromJsonString(invalidJson);

      expect(saveData, isNull);
    });

    test('round trip should preserve all values', () {
      final character = Character(
        name: 'TestPlayer',
        stats: CharacterStats(strength: 5.5, intelligence: 10.25),
        activityCompletions: {'working': 10, 'studying': 5},
      );
      final gameTime = GameTime(initialHour: 18, initialMinute: 45);
      gameTime.update(5000);

      final original = GameSaveData(
        character: character,
        gameTime: gameTime,
        savedAt: DateTime(2026, 1, 27, 12, 30, 45),
        timezone: 'UTC+05:30',
      );

      final jsonString = original.toJsonString();
      final restored = GameSaveData.fromJsonString(jsonString);

      expect(restored, isNotNull);
      expect(restored!.version, equals(original.version));
      expect(restored.savedAt, equals(original.savedAt));
      expect(restored.timezone, equals(original.timezone));
      expect(restored.character.name, equals(original.character.name));
      expect(
        restored.character.stats.strength,
        equals(original.character.stats.strength),
      );
      expect(
        restored.character.getCompletions('working'),
        equals(original.character.getCompletions('working')),
      );
      expect(restored.gameTime.dayCount, equals(original.gameTime.dayCount));
    });
  });

  group('SaveManager', () {
    test('should create with default autosave interval', () {
      final saveManager = SaveManager();

      expect(saveManager.autosaveIntervalSeconds, equals(30));
      expect(saveManager.isAutosaveEnabled, isFalse);
      expect(saveManager.lastSaveTime, isNull);
    });

    test('should create with custom autosave interval', () {
      final saveManager = SaveManager(autosaveIntervalSeconds: 60);

      expect(saveManager.autosaveIntervalSeconds, equals(60));
    });

    test('exportSave should return null when not initialized', () {
      final saveManager = SaveManager();

      final result = saveManager.exportSave();

      expect(result, isNull);
    });

    test('exportSave should return JSON string when initialized', () {
      final saveManager = SaveManager();
      final character = Character(name: 'TestPlayer');
      final gameTime = GameTime();
      saveManager.initialize(character: character, gameTime: gameTime);

      final result = saveManager.exportSave();

      expect(result, isNotNull);
      expect(result, contains('"name":"TestPlayer"'));
    });

    test('importSave should parse valid JSON', () {
      final saveManager = SaveManager();
      const jsonString = '''
        {
          "version": 1,
          "savedAt": "2026-01-27T12:30:45.000",
          "timezone": "UTC+00:00",
          "character": {
            "name": "ImportedPlayer",
            "stats": {
              "strength": 10.0,
              "intelligence": 1.0,
              "endurance": 1.0,
              "charisma": 1.0,
              "agility": 1.0
            },
            "activityCompletions": {"working": 5}
          },
          "gameTime": {
            "timeMultiplier": 300.0,
            "inGameSeconds": 28800.0,
            "dayCount": 3,
            "realTimePlayedMs": 1000.0
          }
        }
      ''';

      final result = saveManager.importSave(jsonString);

      expect(result, isNotNull);
      expect(result!.character.name, equals('ImportedPlayer'));
      expect(result.character.stats.strength, equals(10.0));
      expect(result.character.getCompletions('working'), equals(5));
      expect(result.gameTime.dayCount, equals(3));
    });

    test('importSave should return null for invalid JSON', () {
      final saveManager = SaveManager();

      final result = saveManager.importSave('invalid json');

      expect(result, isNull);
    });

    test('startAutosave should enable autosave', () {
      final saveManager = SaveManager();
      final character = Character(name: 'TestPlayer');
      final gameTime = GameTime();
      saveManager.initialize(character: character, gameTime: gameTime);

      saveManager.startAutosave();

      expect(saveManager.isAutosaveEnabled, isTrue);

      // Clean up
      saveManager.dispose();
    });

    test('stopAutosave should disable autosave', () {
      final saveManager = SaveManager();
      final character = Character(name: 'TestPlayer');
      final gameTime = GameTime();
      saveManager.initialize(character: character, gameTime: gameTime);

      saveManager.startAutosave();
      expect(saveManager.isAutosaveEnabled, isTrue);

      saveManager.stopAutosave();
      expect(saveManager.isAutosaveEnabled, isFalse);

      // Clean up
      saveManager.dispose();
    });

    test('dispose should stop autosave', () {
      final saveManager = SaveManager();
      final character = Character(name: 'TestPlayer');
      final gameTime = GameTime();
      saveManager.initialize(character: character, gameTime: gameTime);

      saveManager.startAutosave();
      saveManager.dispose();

      expect(saveManager.isAutosaveEnabled, isFalse);
    });
  });
}
