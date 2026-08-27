import 'package:realunit_wallet/packages/service/dfx/models/referral/locale_text.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/referral_json_list.dart';

/// Server-side referral programme summary for the current wallet
/// (`GET /v1/realunit/referral/summary`). `eligible` is the authoritative
/// entry gate — see CONTRIBUTING.md "API as Decision Authority".
class ReferralSummaryDto {
  final bool eligible;
  final bool termsAccepted;
  final num? minHolding;
  final int openCount;
  final int creditedCount;
  final num realuSum;
  final num chfSum;
  final String? sharePriceLabel;

  const ReferralSummaryDto({
    required this.eligible,
    required this.termsAccepted,
    this.minHolding,
    required this.openCount,
    required this.creditedCount,
    required this.realuSum,
    required this.chfSum,
    this.sharePriceLabel,
  });

  /// Tile label. Empty API fields and «NAV» copy (Offerte draft 5) fall back
  /// to the localized «Aktienkurs» (Mail Dani 24.08.2026 17:42).
  String? get tileSharePriceLabel {
    final raw = firstNonEmpty([sharePriceLabel]);
    if (raw == null) return null;
    if (RegExp(r'NAV', caseSensitive: false).hasMatch(raw)) return null;
    return raw;
  }

  factory ReferralSummaryDto.fromJson(Map<String, dynamic> json) {
    return ReferralSummaryDto(
      eligible: referralJsonBool(json['eligible']),
      termsAccepted: referralJsonBool(json['termsAccepted']),
      minHolding: referralJsonNum(json['minHolding']),
      openCount: referralJsonInt(json['openCount']),
      creditedCount: referralJsonInt(json['creditedCount']),
      realuSum: referralJsonNum(json['realuSum']) ?? 0,
      chfSum: referralJsonNum(json['chfSum']) ?? 0,
      sharePriceLabel: firstNonEmpty([json['sharePriceLabel'] as String?]),
    );
  }
}
