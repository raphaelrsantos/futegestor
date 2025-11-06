import 'dart:convert';
import 'dart:html' as html; // Only available on web

import 'local_storage_types.dart';

class WebLocalStorageBackend implements LocalStorageBackend {
  const WebLocalStorageBackend();

  @override
  Future<void> init() async {
    // Debug: confirm backend selection on web
    // ignore: avoid_print
    print('LocalStorage backend: web (window.localStorage)');
  }

  @override
  T? read<T>(String key) {
    try {
      final raw = html.window.localStorage[key];
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      return decoded as T?;
    } catch (_) {
      // Drop corrupted entries
      html.window.localStorage.remove(key);
      return null;
    }
  }

  @override
  Future<void> write(String key, dynamic value) async {
    try {
      final sanitized = jsonDecode(jsonEncode(value));
      html.window.localStorage[key] = jsonEncode(sanitized);
    } catch (_) {
      try {
        html.window.localStorage[key] = jsonEncode(value.toString());
      } catch (_) {}
    }
  }

  @override
  Future<void> remove(String key) async {
    html.window.localStorage.remove(key);
  }
}

LocalStorageBackend createLocalStorageBackend() => const WebLocalStorageBackend();
