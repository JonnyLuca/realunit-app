/// Trims, percent-decodes, and caps an invite/promo code at 256 characters.
/// Empty or whitespace-only values (including `%20`) become null.
String? normalizeReferralCode(String? raw) {
  if (raw == null) return null;
  var value = raw.trim();
  if (value.isEmpty) return null;
  try {
    value = Uri.decodeComponent(value).trim();
  } catch (_) {
    // Keep the trimmed raw value when it is not valid percent-encoding.
  }
  if (value.isEmpty) return null;
  return value.length > 256 ? value.substring(0, 256) : value;
}
