import 'package:realunit_wallet/packages/service/dfx/models/referral/locale_text.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/referral_kind.dart';

/// Public `GET /v1/realunit/referral/code/:code` payload for registration
/// preview and the website landing. Accepts `Invite`/`Promo` in either case.
class ReferralCodeLookupDto {
  final String kind;
  final String? inviterName;
  final String? inviteeName;
  final String? actionText;
  final String? campaignText;
  final String? campaignTextEn;

  const ReferralCodeLookupDto({
    required this.kind,
    this.inviterName,
    this.inviteeName,
    this.actionText,
    this.campaignText,
    this.campaignTextEn,
  });

  bool get isPromo => kind.toLowerCase() == 'promo';
  bool get isInvite => kind.toLowerCase() == 'invite';

  /// Locale-aware campaign / action wording. EN falls back to DE when the EN
  /// field is absent or empty.
  String? campaignTextForLocale(String languageCode) {
    if (languageCode == 'en') {
      return firstNonEmpty([campaignTextEn, campaignText, actionText]);
    }
    return firstNonEmpty([actionText, campaignText, campaignTextEn]);
  }

  factory ReferralCodeLookupDto.fromJson(Map<String, dynamic> json) {
    return ReferralCodeLookupDto(
      kind: inferReferralKind(json),
      inviterName: json['inviterName'] as String?,
      inviteeName: json['inviteeName'] as String?,
      actionText: json['actionText'] as String?,
      campaignText: json['campaignText'] as String?,
      campaignTextEn: json['campaignTextEn'] as String?,
    );
  }
}
