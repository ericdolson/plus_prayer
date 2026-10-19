Map<String, dynamic> pick(Map<String, dynamic> map, List<String> keys) {
  return Map.fromEntries(
    map.entries.where((entry) => keys.contains(entry.key)),
  );
}

// Returns a map with all keys from the original map
Map<String, dynamic> trimAndNullifyEmptyStrings(Map<String, dynamic> map) {
  return map.map((key, value) {
    if (value is String) {
      final trimmedValue = value.trim();
      return MapEntry(key, trimmedValue.isEmpty ? null : trimmedValue);
    }

    return MapEntry(key, value);
  });
}
