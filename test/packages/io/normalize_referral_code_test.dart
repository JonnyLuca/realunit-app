import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/io/normalize_referral_code.dart';

void main() {
  test('trims, percent-decodes, and caps at 256 characters', () {
    expect(normalizeReferralCode('  AB12CD  '), 'AB12CD');
    expect(normalizeReferralCode('AB%2F12'), 'AB/12');
    expect(normalizeReferralCode('AB/12'), 'AB/12');
    final long = 'x' * 300;
    expect(normalizeReferralCode(long)!.length, 256);
  });

  test('rejects missing, blank, and whitespace-only decoded values', () {
    expect(normalizeReferralCode(null), isNull);
    expect(normalizeReferralCode(''), isNull);
    expect(normalizeReferralCode('   '), isNull);
    expect(normalizeReferralCode('%20'), isNull);
  });
}
