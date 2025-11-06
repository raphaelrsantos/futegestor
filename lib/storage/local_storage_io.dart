import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'local_storage_types.dart';

class IoLocalStorageBackend implements LocalStorageBackend {
  SharedPreferences? _prefs;

  @override
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    // ignore: avoid_print
    print('LocalStorage backend: io (SharedPreferences)');
  }

  @override
  T? read<T>(String key) {
    final prefs = _prefs;
    if (prefs == null) return null;
    try {
      final raw = prefs.getString(key);
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      return decoded as T?;
    } catch (_) {
      prefs?.remove(key);
      return null;
    }
  }

  @override
  Future<void> write(String key, dynamic value) async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      final sanitized = jsonDecode(jsonEncode(value));
      await prefs.setString(key, jsonEncode(sanitized));
    } catch (_) {
      try {
        await prefs.setString(key, jsonEncode(value.toString()));
      } catch (_) {}
    }
  }

  @override
  Future<void> remove(String key) async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.remove(key);
  }
}

LocalStorageBackend createLocalStorageBackend() => IoLocalStorageBackend();
