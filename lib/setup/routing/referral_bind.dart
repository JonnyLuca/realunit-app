import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_referral_service.dart';
import 'package:realunit_wallet/screens/pin/bloc/auth/pin_auth_cubit.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/setup/routing/referral_pending_code.dart';

/// Binds a stashed or freshly delivered referral code once the session is unlocked.
/// Shows the API campaign text for promo binds. Invite binds stay silent —
/// the invitee is not sent to the referrer overview (they are not the host).
///
/// The stash is consumed after a successful bind. Transport / 5xx / 401 / 429
/// put the code back so the next dashboard landing can retry. 4xx business
/// rejections (invalid, self-referral, already bound, stacking) drop it —
/// retrying those on every unlock would loop forever.
Future<void> bindPendingReferralCode(GoRouter router, {String? code}) async {
  final resolved = code ?? await peekPendingReferralCode();
  if (resolved == null || resolved.isEmpty) return;

  try {
    final result = await getIt<RealUnitReferralService>().bind(code: resolved);
    await clearPendingReferralCode();
    final ctx = router.routerDelegate.navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;

    if (result.isPromo) {
      final lang = Localizations.localeOf(ctx).languageCode;
      final text = result.campaignTextForLocale(lang);
      if (text != null && text.isNotEmpty) {
        await showDialog<void>(
          context: ctx,
          builder: (dialogContext) => AlertDialog(
            title: Text(S.of(dialogContext).referralPromoTitle),
            content: SingleChildScrollView(child: Text(text)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(S.of(dialogContext).close),
              ),
            ],
          ),
        );
      }
    }
  } catch (error) {
    if (_shouldRetryBind(error)) {
      await stashPendingReferralCode(resolved);
    } else {
      await clearPendingReferralCode();
    }
  }
}

bool _shouldRetryBind(Object error) {
  if (error is! ApiException) return true;
  final status = error.statusCode;
  if (status == null) return true;
  return status >= 500 || status == 401 || status == 408 || status == 429;
}

/// Deferred bind used from redirects — re-checks PIN unlock at execution time.
void scheduleReferralBind(GoRouter router, String code) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final pinState = getIt<PinAuthCubit>().state;
    if (!(pinState.isPinVerified && pinState.isPinSetup)) {
      unawaited(stashPendingReferralCode(code));
      return;
    }
    unawaited(bindPendingReferralCode(router, code: code));
  });
}
