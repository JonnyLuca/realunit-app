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
