import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/service/dfx/referral_lookup_status.dart';

void main() {
  test('400/404/409/410/422 are invalid; transport failures are not', () {
    expect(isReferralLookupInvalidStatus(400), isTrue);
    expect(isReferralLookupInvalidStatus(404), isTrue);
    expect(isReferralLookupInvalidStatus(409), isTrue);
    expect(isReferralLookupInvalidStatus(410), isTrue);
    expect(isReferralLookupInvalidStatus(422), isTrue);

    expect(isReferralLookupInvalidStatus(null), isFalse);
    expect(isReferralLookupInvalidStatus(401), isFalse);
    expect(isReferralLookupInvalidStatus(408), isFalse);
    expect(isReferralLookupInvalidStatus(429), isFalse);
    expect(isReferralLookupInvalidStatus(500), isFalse);
    expect(isReferralLookupInvalidStatus(503), isFalse);
  });
}
