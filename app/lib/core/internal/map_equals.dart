/// Whether [a] and [b] have the same keys with equal values (`==`); two
/// `null` maps are equal.
bool mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
  if (identical(a, b)) {
    return true;
  }
  if (a == null || b == null || a.length != b.length) {
    return false;
  }
  for (final MapEntry(:key, :value) in a.entries) {
    if (!b.containsKey(key) || b[key] != value) {
      return false;
    }
  }
  return true;
}

/// A hash consistent with [mapEquals]: independent of the entry order.
int mapHash<K, V>(Map<K, V>? map) => map == null
    ? null.hashCode
    : Object.hashAllUnordered([
        for (final MapEntry(:key, :value) in map.entries)
          Object.hash(key, value),
      ]);
