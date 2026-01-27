import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/character.dart';
import '../models/game_time.dart';

/// Represents a complete game save state.
class GameSaveData {
  /// Creates a new [GameSaveData] instance.
  GameSaveData({
    required this.character,
    required this.gameTime,
    required this.savedAt,
    required this.timezone,
    this.version = 1,
  });

  /// Creates a [GameSaveData] instance from a JSON map.
  factory GameSaveData.fromJson(Map<String, dynamic> json) {
    return GameSaveData(
      character: Character.fromJson(json['character'] as Map<String, dynamic>),
      gameTime: GameTime.fromJson(json['gameTime'] as Map<String, dynamic>),
      savedAt: DateTime.parse(json['savedAt'] as String),
      timezone: json['timezone'] as String? ?? 'UTC',
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }

  /// The character state.
  final Character character;

  /// The game time state.
  final GameTime gameTime;

  /// The real-world time when the save was created.
  final DateTime savedAt;

  /// The timezone of the saved time.
  final String timezone;

  /// The save format version for future compatibility.
  final int version;

  /// Converts this [GameSaveData] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'savedAt': savedAt.toIso8601String(),
      'timezone': timezone,
      'character': character.toJson(),
      'gameTime': gameTime.toJson(),
    };
  }

  /// Converts this save data to a JSON string.
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Creates a [GameSaveData] from a JSON string.
  static GameSaveData? fromJsonString(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return GameSaveData.fromJson(json);
    } catch (e) {
      debugPrint('Error parsing save data: $e');
      return null;
    }
  }
}

/// Manages saving, loading, exporting, and importing game state.
///
/// Features:
/// - Autosave every 30 seconds
/// - Manual save
/// - Export save as JSON string
/// - Import save from JSON string
/// - Local storage persistence using shared_preferences
class SaveManager extends ChangeNotifier {
  /// Creates a new [SaveManager].
  SaveManager({
    this.autosaveIntervalSeconds = 30,
  });

  /// The storage key for the save data.
  static const String _saveKey = 'just_another_day_save';

  /// The interval between autosaves in seconds.
  final int autosaveIntervalSeconds;

  Timer? _autosaveTimer;
  bool _isAutosaveEnabled = false;
  DateTime? _lastSaveTime;
  Character? _character;
  GameTime? _gameTime;

  /// Whether autosave is currently enabled.
  bool get isAutosaveEnabled => _isAutosaveEnabled;

  /// The last time the game was saved.
  DateTime? get lastSaveTime => _lastSaveTime;

  /// Initializes the save manager with the game state references.
  void initialize({
    required Character character,
    required GameTime gameTime,
  }) {
    _character = character;
    _gameTime = gameTime;
  }

  /// Starts the autosave timer.
  void startAutosave() {
    if (_isAutosaveEnabled) return;

    _isAutosaveEnabled = true;
    _autosaveTimer = Timer.periodic(
      Duration(seconds: autosaveIntervalSeconds),
      (_) => save(),
    );
    notifyListeners();
  }

  /// Stops the autosave timer.
  void stopAutosave() {
    _isAutosaveEnabled = false;
    _autosaveTimer?.cancel();
    _autosaveTimer = null;
    notifyListeners();
  }

  /// Gets the current timezone string.
  String _getCurrentTimezone() {
    final now = DateTime.now();
    final offset = now.timeZoneOffset;
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final sign = offset.isNegative ? '-' : '+';
    return 'UTC$sign$hours:$minutes';
  }

  /// Creates a save data object from the current game state.
  GameSaveData? _createSaveData() {
    if (_character == null || _gameTime == null) {
      debugPrint('SaveManager: Cannot create save - not initialized');
      return null;
    }

    return GameSaveData(
      character: _character!,
      gameTime: _gameTime!,
      savedAt: DateTime.now(),
      timezone: _getCurrentTimezone(),
    );
  }

  /// Saves the current game state to local storage.
  ///
  /// Returns true if the save was successful.
  Future<bool> save() async {
    final saveData = _createSaveData();
    if (saveData == null) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = saveData.toJsonString();
      final success = await prefs.setString(_saveKey, jsonString);

      if (success) {
        _lastSaveTime = saveData.savedAt;
        notifyListeners();
        debugPrint('Game saved at ${saveData.savedAt} (${saveData.timezone})');
      }

      return success;
    } catch (e) {
      debugPrint('Error saving game: $e');
      return false;
    }
  }

  /// Loads the game state from local storage.
  ///
  /// Returns the loaded save data, or null if no save exists or loading failed.
  Future<GameSaveData?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_saveKey);

      if (jsonString == null) {
        debugPrint('No save data found');
        return null;
      }

      final saveData = GameSaveData.fromJsonString(jsonString);
      if (saveData != null) {
        _lastSaveTime = saveData.savedAt;
        notifyListeners();
        debugPrint(
          'Game loaded from ${saveData.savedAt} (${saveData.timezone})',
        );
      }

      return saveData;
    } catch (e) {
      debugPrint('Error loading game: $e');
      return null;
    }
  }

  /// Exports the current game state as a JSON string.
  ///
  /// Returns the JSON string, or null if export failed.
  String? exportSave() {
    final saveData = _createSaveData();
    return saveData?.toJsonString();
  }

  /// Imports game state from a JSON string.
  ///
  /// Returns the parsed save data, or null if import failed.
  GameSaveData? importSave(String jsonString) {
    try {
      final saveData = GameSaveData.fromJsonString(jsonString);
      if (saveData != null) {
        debugPrint(
          'Imported save from ${saveData.savedAt} (${saveData.timezone})',
        );
      }
      return saveData;
    } catch (e) {
      debugPrint('Error importing save: $e');
      return null;
    }
  }

  /// Checks if a save exists in local storage.
  Future<bool> hasSave() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_saveKey);
    } catch (e) {
      return false;
    }
  }

  /// Deletes the save from local storage.
  Future<bool> deleteSave() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.remove(_saveKey);
      if (success) {
        _lastSaveTime = null;
        notifyListeners();
        debugPrint('Save deleted');
      }
      return success;
    } catch (e) {
      debugPrint('Error deleting save: $e');
      return false;
    }
  }

  /// Disposes of the save manager and stops autosave.
  @override
  void dispose() {
    stopAutosave();
    super.dispose();
  }
}
