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
