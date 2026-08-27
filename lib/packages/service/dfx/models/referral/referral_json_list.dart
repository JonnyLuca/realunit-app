/// Reads a JSON array of objects, including DFX wrappers
/// (`invites` / `payouts` / `data` / `items`). Unknown shapes yield `[]`
/// so a wrapper cannot hide open invites or settled prizes.
List<Map<String, dynamic>> referralJsonList(dynamic decoded) {
  if (decoded is List) {
    return [
      for (final item in decoded)
        if (item is Map<String, dynamic>) item,
    ];
  }
  if (decoded is Map<String, dynamic>) {
    for (final key in const ['invites', 'payouts', 'data', 'items']) {
      final value = decoded[key];
      if (value is List) {
        return [
          for (final item in value)
            if (item is Map<String, dynamic>) item,
        ];
      }
    }
  }
  return const [];
}

/// JSON numbers sometimes arrive as strings (`"20"`, `"246.50"`). Missing or
/// non-numeric values are null so a prize row is not silently shown as 0.
num? referralJsonNum(dynamic value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value.trim());
  return null;
}

int referralJsonInt(dynamic value, {int orElse = 0}) =>
    referralJsonNum(value)?.round() ?? orElse;

DateTime _fromEpoch(num value) {
  final n = value.toInt();
  if (n.abs() >= 100000000000) {
    return DateTime.fromMillisecondsSinceEpoch(n, isUtc: true);
  }
  return DateTime.fromMillisecondsSinceEpoch(n * 1000, isUtc: true);
}

/// ISO-8601 strings or Unix seconds/milliseconds. Null if missing/unparseable.
DateTime? referralJsonDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is num) return _fromEpoch(value);
  if (value is String) {
    final text = value.trim();
    if (text.isEmpty) return null;
    try {
      return DateTime.parse(text);
    } catch (_) {
      final n = num.tryParse(text);
      if (n != null) return _fromEpoch(n);
      return null;
    }
  }
  return null;
}
