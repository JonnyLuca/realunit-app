import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:realunit_wallet/packages/io/normalize_referral_code.dart';

/// SharedPreferences key for a referral/promo invite code delivered via
/// deeplink before the user is authenticated.
const String pendingReferralCodeKey = 'pending_referral_code';

/// In-process stash mirroring [stashPendingPaymentDeeplink]: last-write-wins,
/// no queue. Survives warm-locked PIN screens within the same process.
String? _pendingReferralCode;

/// Guards [takePendingReferralCode] across the first `await` so a parallel
/// boot bind cannot read prefs after memory was claimed.
bool _takingPendingReferralCode = false;

/// Persist [code] for post-unlock / post-KYC bind.
///
/// Sources: custom-scheme / https App Links, the registration field, and
/// (Android) the Play install referrer captured once per install. If iOS
/// drops the first open after a fresh install, the user re-taps the invite
/// link and this stash is filled again — that re-tap path is intentional.
Future<void> stashPendingReferralCode(String code) async {
  final capped = referralCodeFromInput(code);
  if (capped == null) return;
  _pendingReferralCode = capped;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(pendingReferralCodeKey, capped);
}

/// Returns and clears the pending code (memory + SharedPreferences).
Future<String?> takePendingReferralCode() async {
  if (_takingPendingReferralCode) return null;
  _takingPendingReferralCode = true;
  try {
    final inMemory = _pendingReferralCode;
    _pendingReferralCode = null;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(pendingReferralCodeKey);
    await prefs.remove(pendingReferralCodeKey);
    return referralCodeFromInput(inMemory ?? stored);
  } finally {
    _takingPendingReferralCode = false;
  }
}

/// Clears any stashed code without returning it.
Future<void> clearPendingReferralCode() async {
  _pendingReferralCode = null;
  _takingPendingReferralCode = false;
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(pendingReferralCodeKey);
}

/// Drop the stash only if it still equals [code]. A newer distinct code
/// that landed after a successful bind is left for the next take.
Future<void> discardPendingReferralCodeIfEqual(String code) async {
  final capped = referralCodeFromInput(code);
  if (capped == null) return;
  if (_takingPendingReferralCode) return;
  _takingPendingReferralCode = true;
  try {
    final inMemory = referralCodeFromInput(_pendingReferralCode);
    if (inMemory != null && inMemory != capped) return;
    final prefs = await SharedPreferences.getInstance();
    final stored = referralCodeFromInput(prefs.getString(pendingReferralCodeKey));
    final current = inMemory ?? stored;
    if (current != capped) return;
    _pendingReferralCode = null;
    await prefs.remove(pendingReferralCodeKey);
  } finally {
    _takingPendingReferralCode = false;
  }
}

/// Read-only peek (memory first, then SharedPreferences). Does not clear.
/// Percent-decodes values written before stash-time normalize.
Future<String?> peekPendingReferralCode() async {
  if (_pendingReferralCode != null) {
    return referralCodeFromInput(_pendingReferralCode);
  }
  final prefs = await SharedPreferences.getInstance();
  return referralCodeFromInput(prefs.getString(pendingReferralCodeKey));
}

/// Synchronous in-memory peek for redirect tests / warm paths that already
/// stashed in this process. Does not read SharedPreferences.
@visibleForTesting
String? peekPendingReferralCodeSync() =>
    referralCodeFromInput(_pendingReferralCode);

/// Test-only: seed the in-memory stash without touching SharedPreferences.
@visibleForTesting
void debugSetPendingReferralCodeSync(String? code) {
  _pendingReferralCode = code;
  _takingPendingReferralCode = false;
}
