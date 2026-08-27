/// Extracts an invite/promo code from a Play Store install-referrer string.
///
/// The website attaches `referrer=invite=<code>`. Play delivers that as
/// `invite=<code>` (sometimes still percent-encoded). Returns null when no
/// code is present. Caps at 256 characters, same as [stashPendingReferralCode].
String? parseInviteCodeFromReferrer(String? raw) {
  if (raw == null || raw.isEmpty) return null;

  var decoded = raw;
  try {
    decoded = Uri.decodeComponent(raw);
  } catch (_) {
    decoded = raw;
  }

  final params = Uri.splitQueryString(decoded);
  final rawCode = params['invite'] ?? params['promo'] ?? params['code'];
  if (rawCode == null) return null;
  final trimmed = rawCode.trim();
  if (trimmed.isEmpty) return null;
  return trimmed.length > 256 ? trimmed.substring(0, 256) : trimmed;
}
