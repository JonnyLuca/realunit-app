import 'package:realunit_wallet/packages/service/dfx/models/referral/locale_text.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/referral_json_list.dart';

/// One invite row from `GET /v1/realunit/referral/invites`.
/// Status values from the API: `Open` / `Bound` / `Credited` / `Deleted`.
/// The UI only surfaces Open as "offen" and Credited as "gutgeschrieben".
class ReferralInviteDto {
  final int id;
  final String code;
  final String url;
  final String guestName;
  final String status;
  final DateTime created;
  final String? copyText;
  final String? copyTextEn;

  const ReferralInviteDto({
    required this.id,
    required this.code,
    required this.url,
    required this.guestName,
    required this.status,
    required this.created,
    this.copyText,
    this.copyTextEn,
  });

  bool get isOpen => status.toLowerCase() == 'open';
  bool get isCredited => status.toLowerCase() == 'credited';

  String? copyTextForLocale(String languageCode) {
    if (languageCode == 'en') {
      return firstNonEmpty([copyTextEn, copyText]);
    }
    return firstNonEmpty([copyText, copyTextEn]);
  }

  factory ReferralInviteDto.fromJson(Map<String, dynamic> json) {
    final created = referralJsonDate(json['created']);
    final code = referralJsonString(json['code']);
    final url = referralInviteUrl(url: json['url'], code: code);
    final guestName = referralJsonString(json['guestName']);
    if (created == null || code == null || url == null || guestName == null) {
      throw FormatException('referral invite missing fields');
    }
    return ReferralInviteDto(
      id: referralJsonInt(json['id']),
      code: code,
      url: url,
      guestName: guestName,
      status: referralJsonString(json['status']) ?? '',
      created: created,
      copyText: referralJsonString(json['copyText']),
      copyTextEn: referralJsonString(json['copyTextEn']),
    );
  }
}
