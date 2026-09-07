import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:realunit_wallet/setup/routing/referral_pending_code.dart';

/// Persist a looked-up invite/promo code after KYC submit.
///
/// Null means skip or invalid lookup: leave any deeplink stash in place so
/// automatic takeover still binds. Only a resolved (empty-cleared or valid)
/// code is written.
Future<void> stashResolvedReferralCode(String? resolved) async {
  final override = debugStashResolvedReferralCode;
  if (override != null) {
    await override(resolved);
    return;
  }
  if (resolved == null) return;
  await stashPendingReferralCode(resolved);
}

@visibleForTesting
Future<void> Function(String? resolved)? debugStashResolvedReferralCode;

/// Typed registration-field code. Skip/invalid discard this code without
/// touching a newer distinct deeplink. [awaitIdle] must run before submit
/// so a crash after backend accept still has the code in prefs.
class TypedReferralStash {
  String? resolved;
  Future<void> _inflight = Future<void>.value();

  Future<void> onResolved(String? code) {
    final previous = resolved;
    resolved = code;
    _inflight = _inflight.then((_) => _apply(code, previous));
    return _inflight;
  }

  Future<void> awaitIdle() => _inflight;

  Future<void> _apply(String? code, String? previous) async {
    try {
      if (code != null) {
        await stashResolvedReferralCode(code);
      } else if (previous != null) {
        await discardPendingReferralCodeIfEqual(previous);
      }
    } catch (e) {
      developer.log('Failed to persist typed referral code: $e');
    }
  }
}
