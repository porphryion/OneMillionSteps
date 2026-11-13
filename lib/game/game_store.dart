import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'game_state.dart';

abstract class GameStore {
  /// Null when there is no save, or the save is from an older version.
  Future<GameState?> load();
  Future<void> save(GameState state);
}

class PrefsGameStore implements GameStore {
  PrefsGameStore(this._prefs);

  static const _key = 'game_state';
  final SharedPreferences _prefs;

  @override
  Future<GameState?> load() async {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    return GameState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> save(GameState state) =>
      _prefs.setString(_key, jsonEncode(state.toJson()));
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
