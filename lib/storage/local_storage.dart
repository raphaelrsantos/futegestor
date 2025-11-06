import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple JSON-based key/value storage with platform-specific backends.
/// - Web: window.localStorage
/// - Mobile/Desktop: SharedPreferences
class LocalStorage {
  LocalStorage._();
  static final LocalStorage instance = LocalStorage._();

  static SharedPreferences? _prefs;
  static bool _memoryOnly = false;
  static final Map<String, String> _memory = {};

  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      // ignore: avoid_print
      print('LocalStorage backend: SharedPreferences');
    } catch (e) {
      // Fallback for environments without plugin support (e.g., constrained web preview)
      _memoryOnly = true;
      // ignore: avoid_print
      print('LocalStorage backend: in-memory (fallback). Reason: $e');
    }
  }

  T? read<T>(String key) {
    try {
      final raw = _memoryOnly ? _memory[key] : _prefs?.getString(key);
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      return decoded as T?;
    } catch (_) {
      remove(key);
      return null;
    }
  }

  Future<void> write(String key, dynamic value) async {
    try {
      final sanitized = jsonDecode(jsonEncode(value));
      final payload = jsonEncode(sanitized);
      if (_memoryOnly) {
        _memory[key] = payload;
      } else {
        await _prefs?.setString(key, payload);
      }
    } catch (_) {
      try {
        final payload = jsonEncode(value.toString());
        if (_memoryOnly) {
          _memory[key] = payload;
        } else {
          await _prefs?.setString(key, payload);
        }
      } catch (_) {}
    }
  }

  Future<void> remove(String key) async {
    if (_memoryOnly) {
      _memory.remove(key);
    } else {
      await _prefs?.remove(key);
    }
  }
}
