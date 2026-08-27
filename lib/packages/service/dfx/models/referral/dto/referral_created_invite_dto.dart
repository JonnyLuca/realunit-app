import 'package:realunit_wallet/packages/service/dfx/models/referral/locale_text.dart';

/// Response from `POST /v1/realunit/referral/invites`.
/// The server generates the personalised share text; the app renders it 1:1.
class ReferralCreatedInviteDto {
  final String code;
  final String url;
  final String guestName;
  final String? copyText;
  final String? copyTextEn;

  const ReferralCreatedInviteDto({
    required this.code,
    required this.url,
    required this.guestName,
    this.copyText,
    this.copyTextEn,
  });

  /// Locale-aware share wording. EN falls back to DE when the EN field is absent
  /// or empty.
  String? copyTextForLocale(String languageCode) {
    if (languageCode == 'en') {
      return firstNonEmpty([copyTextEn, copyText]);
    }
    return firstNonEmpty([copyText, copyTextEn]);
  }

  factory ReferralCreatedInviteDto.fromJson(Map<String, dynamic> json) {
    return ReferralCreatedInviteDto(
      code: json['code'] as String,
      url: json['url'] as String,
      guestName: json['guestName'] as String,
      copyText: json['copyText'] as String?,
      copyTextEn: json['copyTextEn'] as String?,
    );
  }
}
