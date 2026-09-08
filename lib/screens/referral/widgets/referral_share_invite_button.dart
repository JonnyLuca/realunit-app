import 'dart:async';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/referral/share_referral_invite.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';

/// Shares the personalised invite text. A second tap while the sheet is
/// open is ignored. A platform share failure keeps the label in the error
/// state for 2s and stays tappable. A new share text while the sheet is
/// open does not show that error on the new invite. If the sheet never
/// returns, resuming the app clears loading so Versenden is tappable.
class ReferralShareInviteButton extends StatefulWidget {
  final String text;
  final bool autofocus;

  const ReferralShareInviteButton({
    super.key,
    required this.text,
    this.autofocus = false,
  });

  @override
  State<ReferralShareInviteButton> createState() =>
      _ReferralShareInviteButtonState();
}

class _ReferralShareInviteButtonState extends State<ReferralShareInviteButton>
    with WidgetsBindingObserver {
  Timer? _reset;
  Timer? _shareTimeout;
  bool _failed = false;
  bool _sharing = false;
  int _shareGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(ReferralShareInviteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text == widget.text || (!_failed && !_sharing)) return;
    _reset?.cancel();
    _failed = false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reset?.cancel();
    _shareTimeout?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_sharing) return;
    // Abandon the hung sheet for good: bump the generation so a late reply is
    // ignored, and cancel the timeout so no stray timer outlives the tap.
    _shareGeneration++;
    _shareTimeout?.cancel();
    _shareTimeout = null;
    setState(() => _sharing = false);
  }

  Future<void> _share() async {
    if (_sharing) return;
    final generation = ++_shareGeneration;
    setState(() {
      _sharing = true;
      _failed = false;
    });
    final text = widget.text;
    final subject = S.of(context).referralInviteUrlLabel;
    // Own the timeout instead of using Future.timeout: its timer cannot be
    // cancelled, so a sheet that never returns would leave a pending timer and
    // throw a TimeoutException into a future nobody awaits.
    final settled = Completer<ShareResult?>();
    _shareTimeout?.cancel();
    _shareTimeout = Timer(const Duration(seconds: 30), () {
      if (!settled.isCompleted) settled.complete(null);
    });
    unawaited(() async {
      try {
        final r = await shareReferralInvite(
          context: context,
          text: text,
          subject: subject,
        );
        if (!settled.isCompleted) settled.complete(r);
      } catch (_) {
        if (!settled.isCompleted) settled.complete(null);
      }
    }());
    try {
      final result = await settled.future;
      _shareTimeout?.cancel();
      _shareTimeout = null;
      if (!mounted || generation != _shareGeneration || widget.text != text) {
        return;
      }
      // null means the sheet timed out or the platform threw: neither reported
      // a successful share, so both surface the same transient failure.
      if (result != null && result.status != ShareResultStatus.unavailable) {
        return;
      }
      setState(() => _failed = true);
      _reset?.cancel();
      _reset = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _failed = false);
      });
    } finally {
      if (mounted && generation == _shareGeneration) {
        setState(() => _sharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFilledButton(
      label: S.of(context).referralShareInviteLink,
      autofocus: widget.autofocus && !_failed && !_sharing,
      state: _sharing
          ? FilledButtonState.loading
          : _failed
              ? FilledButtonState.error
              : FilledButtonState.idle,
      onPressed: _sharing ? null : _share,
    );
  }
}
