import 'package:realunit_wallet/packages/service/dfx/models/referral/locale_text.dart';

/// Resolves Invite vs Promo when the API omits `kind`.
/// Explicit `kind` always wins. Otherwise an inviter name is an invite;
/// campaign/action text without an inviter is a promo.
String inferReferralKind(
  Map<String, dynamic> json, {
  String fallback = 'invite',
}) {
  final raw = json['kind'] as String?;
  if (raw != null && raw.trim().isNotEmpty) return raw.trim();
  final inviter = json['inviterName'] as String?;
  if (inviter != null && inviter.trim().isNotEmpty) return 'invite';
  if (firstNonEmpty([
        json['campaignText'] as String?,
        json['campaignTextEn'] as String?,
        json['actionText'] as String?,
      ]) !=
      null) {
    return 'promo';
  }
  return fallback;
}
