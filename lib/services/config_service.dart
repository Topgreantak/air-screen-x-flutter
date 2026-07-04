import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/display_config.dart';

// Persists local prefs (host IP, FPS, display) in UserDefaults via shared_preferences.
class ConfigService {
  static const _key = 'idisplay_prefs';

  Future<Prefs> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_key);
    if (raw == null) return const Prefs();
    try {
      return Prefs.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const Prefs(); // corrupt → defaults
    }
  }

  Future<void> save(Prefs p) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, jsonEncode(p.toJson()));
  }
}
