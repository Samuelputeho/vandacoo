import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesWithCache {
  final SharedPreferences _prefs;

  SharedPreferencesWithCache._(this._prefs);

  factory SharedPreferencesWithCache.fromPrefs(SharedPreferences prefs) =>
      SharedPreferencesWithCache._(prefs);

  static Future<SharedPreferencesWithCache> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesWithCache._(prefs);
  }

  Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);
  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);
  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);
  Future<bool> setDouble(String key, double value) =>
      _prefs.setDouble(key, value);
  Future<bool> setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);

  String? getString(String key) => _prefs.getString(key);
  int? getInt(String key) => _prefs.getInt(key);
  bool? getBool(String key) => _prefs.getBool(key);
  double? getDouble(String key) => _prefs.getDouble(key);
  List<String>? getStringList(String key) => _prefs.getStringList(key);

  Future<bool> remove(String key) => _prefs.remove(key);
  Future<bool> clear() => _prefs.clear();
  Set<String> getKeys() => _prefs.getKeys();
  bool containsKey(String key) => _prefs.containsKey(key);
  Future<void> reload() => _prefs.reload();
}
