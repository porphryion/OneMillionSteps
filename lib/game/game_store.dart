import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'game_state.dart';

abstract class GameStore {
  /// Null when there is no save, or the save is from an older version.
  Future<GameState?> load();
  Future<void> save(GameState state);
}

class PrefsGameStore implements GameStore {
  PrefsGameStore(this._prefs, {this.key = fakeStepsKey});

  /// Saves played with fake steps (test buttons).
  static const fakeStepsKey = 'game_state';

  /// Saves played with real steps from Apple Health. Kept apart so test
  /// progress never mixes with real progress.
  static const healthStepsKey = 'game_state_health';

  final SharedPreferences _prefs;
  final String key;

  @override
  Future<GameState?> load() async {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    return GameState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> save(GameState state) =>
      _prefs.setString(key, jsonEncode(state.toJson()));
}

class MemoryGameStore implements GameStore {
  String? _raw;

  @override
  Future<GameState?> load() async => _raw == null
      ? null
      : GameState.fromJson(jsonDecode(_raw!) as Map<String, dynamic>);

  @override
  Future<void> save(GameState state) async => _raw = jsonEncode(state.toJson());
}
