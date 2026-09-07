import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/stash_resolved_referral_code.dart';
import 'package:realunit_wallet/setup/routing/referral_pending_code.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    debugSetPendingReferralCodeSync(null);
    debugStashResolvedReferralCode = null;
  });

  tearDown(() {
    debugStashResolvedReferralCode = null;
  });

  test('null resolved leaves a deeplink stash in place', () async {
    await stashPendingReferralCode('AB12CD');
    await stashResolvedReferralCode(null);
    expect(await peekPendingReferralCode(), 'AB12CD');
  });

  test('a resolved code overwrites the stash for post-auth bind', () async {
    await stashPendingReferralCode('OLD1');
    await stashResolvedReferralCode('EVT1');
    expect(await peekPendingReferralCode(), 'EVT1');
  });

  test('Skip discards the typed code and does not bind it later', () async {
    final stash = TypedReferralStash();
    await stash.onResolved('AB12CD');
    expect(await peekPendingReferralCode(), 'AB12CD');

    await stash.onResolved(null);
    expect(stash.resolved, isNull);
    expect(await peekPendingReferralCode(), isNull);
  });

  test('Skip leaves a distinct deeplink when nothing was typed', () async {
    await stashPendingReferralCode('EVT1');
    final stash = TypedReferralStash();
    await stash.onResolved(null);
    expect(await peekPendingReferralCode(), 'EVT1');
  });

  test('awaitIdle finishes the stash before submit can run', () async {
    final gate = Completer<void>();
    var stashed = false;
    debugStashResolvedReferralCode = (code) async {
      await gate.future;
      stashed = true;
    };
    final stash = TypedReferralStash();
    unawaited(stash.onResolved('AB12CD'));
    var submitReady = false;
    final pending = stash.awaitIdle().then((_) => submitReady = true);
    await Future<void>.value();
    expect(submitReady, isFalse);
    expect(stashed, isFalse);
    gate.complete();
    await pending;
    expect(stashed, isTrue);
    expect(submitReady, isTrue);
  });
}
