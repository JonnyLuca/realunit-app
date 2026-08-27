import 'package:realunit_wallet/packages/service/dfx/models/referral/locale_text.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/referral_json_list.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/referral_kind.dart';

/// Response from `POST /v1/realunit/referral/bind`.
/// For `kind == Promo`, [campaignText] / [campaignTextEn] carry the prescribed
/// wording from the API — do not compose campaign copy in the app.
class ReferralBindResultDto {
  final String kind;
  final String? campaignText;
  final String? campaignTextEn;
  final String? actionText;
  final num? minBuyRealu;
  final DateTime? validUntil;
  final num? redemptionCap;

  const ReferralBindResultDto({
    required this.kind,
    this.campaignText,
    this.campaignTextEn,
    this.actionText,
    this.minBuyRealu,
    this.validUntil,
    this.redemptionCap,
  });

  bool get isPromo => kind.toLowerCase() == 'promo';
  bool get isInvite => kind.toLowerCase() == 'invite';

  /// Locale-aware campaign wording. EN falls back to DE when the EN field is
  /// absent or empty.
  String? campaignTextForLocale(String languageCode) {
    if (languageCode == 'en') {
      return firstNonEmpty([campaignTextEn, campaignText, actionText]);
    }
    return firstNonEmpty([campaignText, actionText, campaignTextEn]);
  }

  factory ReferralBindResultDto.fromJson(Map<String, dynamic> json) {
    final kind = inferReferralKind(json);
    final minBuy = referralJsonNum(json['minBuyRealu']);
    return ReferralBindResultDto(
      kind: kind,
      campaignText: json['campaignText'] as String?,
      campaignTextEn: json['campaignTextEn'] as String?,
      actionText: json['actionText'] as String?,
      // Promo first-purchase floor. Spec default is 200 REALU when omitted.
      minBuyRealu: minBuy ?? (kind.toLowerCase() == 'promo' ? 200 : null),
      validUntil: json['validUntil'] != null
          ? DateTime.parse(json['validUntil'] as String)
          : null,
      redemptionCap: referralJsonNum(json['redemptionCap']),
    );
  }
}
