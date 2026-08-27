import 'package:realunit_wallet/packages/service/dfx/models/referral/referral_json_list.dart';

/// One referral payout row from `GET /v1/realunit/referral/payouts`.
/// [chfValue] is the CHF amount frozen at credit — never recompute from current price.
class ReferralPayoutDto {
  final int id;
  final num amount;
  final num chfValue;
  final DateTime created;
  final String kind;
  final String status;
  final String? txHash;

  const ReferralPayoutDto({
    required this.id,
    required this.amount,
    required this.chfValue,
    required this.created,
    required this.kind,
    required this.status,
    this.txHash,
  });

  /// History only shows a prize after the on-chain transfer is confirmed
  /// (Offerte Punkt 4). Pending/failed rows stay off the ledger.
  bool get isSettled {
    final s = status.toLowerCase();
    if (s.isEmpty) return true;
    return s == 'complete' ||
        s == 'completed' ||
        s == 'credited' ||
        s == 'success' ||
        s == 'confirmed';
  }

  factory ReferralPayoutDto.fromJson(Map<String, dynamic> json) {
    final amount = referralJsonNum(json['amount']);
    final chfValue = referralJsonNum(json['chfValue']);
    final created = referralJsonDate(json['created']);
    if (amount == null || chfValue == null || created == null) {
      throw FormatException('referral payout missing amount/chfValue/created');
    }
    return ReferralPayoutDto(
      id: referralJsonInt(json['id']),
      amount: amount,
      chfValue: chfValue,
      created: created,
      kind: json['kind'] as String? ?? '',
      status: json['status'] as String? ?? 'Complete',
      txHash: json['txHash'] as String?,
    );
  }
}
