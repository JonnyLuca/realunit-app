import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/setup/routing/referral_pending_code.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    debugSetPendingReferralCodeSync(null);
  });

  test('stash then peek then take: take clears, peek does not', () async {
    await stashPendingReferralCode('  AB12CD  ');
    expect(await peekPendingReferralCode(), 'AB12CD');
    expect(peekPendingReferralCodeSync(), 'AB12CD');

    expect(await takePendingReferralCode(), 'AB12CD');
    expect(await peekPendingReferralCode(), isNull);
    expect(await takePendingReferralCode(), isNull);
  });

  test('ignores empty stash and caps at 256 characters', () async {
    await stashPendingReferralCode('   ');
    expect(await peekPendingReferralCode(), isNull);

    final long = 'x' * 300;
    await stashPendingReferralCode(long);
    expect((await peekPendingReferralCode())!.length, 256);
  });

  test('percent-decodes a stashed code', () async {
    await stashPendingReferralCode('AB%2F12');
    expect(await peekPendingReferralCode(), 'AB/12');
  });

  test('clear drops both memory and prefs', () async {
    await stashPendingReferralCode('EVT1');
    await clearPendingReferralCode();
    expect(await peekPendingReferralCode(), isNull);
    expect(peekPendingReferralCodeSync(), isNull);
  });
}
