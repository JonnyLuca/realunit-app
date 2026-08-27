import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_code_lookup_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_referral_service.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/form/labeled_text_field.dart';

/// Optional invite/promo code on registration. Looks up the public code
/// route and shows the invite recognition copy or the promo campaign dialog.
class ReferralCodeField extends StatefulWidget {
  final TextEditingController controller;

  /// Injected in tests. Production uses [RealUnitReferralService.lookupCode].
  final Future<ReferralCodeLookupDto> Function(String code)? lookup;

  /// When false, the surrounding page already shows the heading (AppBar).
  final bool showHeading;

  const ReferralCodeField({
    super.key,
    required this.controller,
    this.lookup,
    this.showHeading = true,
  });

  @override
  State<ReferralCodeField> createState() => _ReferralCodeFieldState();
}

class _ReferralCodeFieldState extends State<ReferralCodeField> {
  Timer? _debounce;
  ReferralCodeLookupDto? _result;
  bool _invalid = false;
  bool _loading = false;
  String? _shownPromoFor;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    if (widget.controller.text.trim().isNotEmpty) {
      _scheduleLookup();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() => _scheduleLookup();

  void _scheduleLookup() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _runLookup);
  }

  Future<ReferralCodeLookupDto?> _lookup(String code) async {
    if (widget.lookup != null) return widget.lookup!(code);
    if (!getIt.isRegistered<RealUnitReferralService>()) return null;
    return getIt<RealUnitReferralService>().lookupCode(code);
  }

  Future<void> _runLookup() async {
    final code = widget.controller.text.trim();
    if (code.isEmpty) {
      if (mounted) {
        setState(() {
          _result = null;
          _invalid = false;
          _loading = false;
        });
      }
      return;
    }

    if (mounted) setState(() => _loading = true);
    try {
      final result = await _lookup(code);
      if (!mounted) return;
      setState(() {
        _result = result;
        _invalid = false;
        _loading = false;
      });
      if (result != null && result.isPromo) {
        await _maybeShowPromo(code, result);
      }
    } on ApiException {
      if (!mounted) return;
      setState(() {
        _result = null;
        _invalid = true;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _result = null;
        _invalid = false;
        _loading = false;
      });
    }
  }

  Future<void> _maybeShowPromo(
    String code,
    ReferralCodeLookupDto result,
  ) async {
    if (_shownPromoFor == code) return;
    final lang = Localizations.localeOf(context).languageCode;
    final text = result.campaignTextForLocale(lang);
    if (text == null || text.isEmpty) return;
    _shownPromoFor = code;
    await showDialog<void>(
      context: context,
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

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final inviter = _result?.inviterName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        if (widget.showHeading)
          Text(
            s.referralCodeHeading,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        Text(
          s.referralCodeDescription,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: RealUnitColors.neutral500,
          ),
        ),
        LabeledTextField(
          label: s.referralCodeOptional,
          hintText: s.referralCodeHint,
          controller: widget.controller,
          textCapitalization: TextCapitalization.characters,
        ),
        if (_loading)
          const Align(
            alignment: Alignment.centerLeft,
            child: CupertinoActivityIndicator(),
          ),
        if (_invalid)
          Text(
            s.referralCodeInvalid,
            style: TextStyle(color: RealUnitColors.status.red600),
          ),
        if (_result != null && _result!.isInvite && inviter != null && inviter.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: RealUnitColors.brand700,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              s.referralInviteRecognized(inviter),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: RealUnitColors.darkBlue,
              ),
            ),
          ),
        if (_result != null && _result!.isPromo)
          Builder(
            builder: (context) {
              final lang = Localizations.localeOf(context).languageCode;
              final text = _result!.campaignTextForLocale(lang);
              if (text == null || text.isEmpty) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: RealUnitColors.brand700,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: RealUnitColors.darkBlue,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
