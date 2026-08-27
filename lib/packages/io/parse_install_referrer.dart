import 'package:realunit_wallet/packages/io/normalize_referral_code.dart';

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
  return normalizeReferralCode(
    params['invite'] ?? params['promo'] ?? params['code'],
  );
}
