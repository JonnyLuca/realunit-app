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

  /// Locale-aware campaign / action wording. EN falls back to DE.
  String? campaignTextForLocale(String languageCode) {
    if (languageCode == 'en') {
      return campaignTextEn ?? campaignText ?? actionText;
    }
    return actionText ?? campaignText ?? campaignTextEn;
  }

  factory ReferralCodeLookupDto.fromJson(Map<String, dynamic> json) {
    return ReferralCodeLookupDto(
      kind: json['kind'] as String? ?? 'invite',
      inviterName: json['inviterName'] as String?,
      inviteeName: json['inviteeName'] as String?,
      actionText: json['actionText'] as String?,
      campaignText: json['campaignText'] as String?,
      campaignTextEn: json['campaignTextEn'] as String?,
    );
  }
}
