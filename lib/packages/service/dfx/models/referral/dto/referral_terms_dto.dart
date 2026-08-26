/// `GET /v1/realunit/referral/terms`. Markdown is authored on the API;
/// the app renders it 1:1. Bundled assets are a fallback only.
class ReferralTermsDto {
  final String version;
  final String markdown;
  final String? markdownEn;

  const ReferralTermsDto({
    required this.version,
    required this.markdown,
    this.markdownEn,
  });

  String textForLang(String languageCode) {
    if (languageCode == 'en') return markdownEn ?? markdown;
    return markdown;
  }

  factory ReferralTermsDto.fromJson(Map<String, dynamic> json) {
    return ReferralTermsDto(
      version: json['version'] as String? ?? '',
      markdown: json['markdown'] as String? ?? '',
      markdownEn: json['markdownEn'] as String?,
    );
  }
}
