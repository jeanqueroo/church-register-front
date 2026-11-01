class TimedCache<T> {
  TimedCache({this.ttl = const Duration(minutes: 3)});

  final Duration ttl;
  final Map<String, _TimedCacheEntry<T>> _entries = {};

  T? get(String key) {
    final entry = _entries[key];
    if (entry == null || entry.expiresAt.isBefore(DateTime.now())) {
      _entries.remove(key);
      return null;
    }
    return entry.value;
  }

  void set(String key, T value) {
    _entries[key] = _TimedCacheEntry(
      value: value,
      expiresAt: DateTime.now().add(ttl),
    );
  }

  void invalidate(String key) => _entries.remove(key);
}

class _TimedCacheEntry<T> {
  const _TimedCacheEntry({
    required this.value,
    required this.expiresAt,
  });

  final T value;
  final DateTime expiresAt;
}
