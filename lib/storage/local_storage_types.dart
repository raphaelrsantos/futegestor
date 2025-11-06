abstract class LocalStorageBackend {
  Future<void> init();
  T? read<T>(String key);
  Future<void> write(String key, dynamic value);
  Future<void> remove(String key);
}
