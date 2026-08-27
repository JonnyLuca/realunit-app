import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_referral_service.dart';
import 'package:realunit_wallet/screens/referral/cubit/referral_cubit.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/setup/di.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';
import 'package:realunit_wallet/widgets/scrollable_actions_layout.dart';

class ReferralTermsPage extends StatefulWidget {
  /// Pre-loaded markdown for golden tests.
  @visibleForTesting
  final String? initialMarkdownContent;

  const ReferralTermsPage({super.key, this.initialMarkdownContent});

  @override
  State<ReferralTermsPage> createState() => _ReferralTermsPageState();
}

class _ReferralTermsPageState extends State<ReferralTermsPage> {
  String? _markdown;
  bool _loadFailed = false;
  bool _accepted = false;
  bool _loadStarted = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialMarkdownContent != null) {
      _markdown = widget.initialMarkdownContent;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadStarted || widget.initialMarkdownContent != null) return;
    _loadStarted = true;
    _loadMarkdown();
  }

  String _languageCode() {
    if (getIt.isRegistered<SettingsBloc>()) {
      return getIt<SettingsBloc>().state.language.code;
    }
    return Localizations.localeOf(context).languageCode;
  }

  Future<void> _loadMarkdown() async {
    final code = _languageCode();
    try {
      if (getIt.isRegistered<RealUnitReferralService>()) {
        final terms = await getIt<RealUnitReferralService>().getTerms();
        final fromApi = terms.textForLang(code);
        if (fromApi.isNotEmpty) {
          if (mounted) setState(() => _markdown = fromApi);
          return;
        }
      }
    } catch (_) {
      // Bundled TB 14.08 is the fallback when the API is unreachable.
    }
    final assetPath = 'assets/legal/referral_terms_$code.md';
    try {
      final content = await rootBundle.loadString(assetPath, cache: false);
      if (mounted) setState(() => _markdown = content);
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.referralTermsTitle)),
      body: SafeArea(
        child: BlocBuilder<ReferralCubit, ReferralState>(
          builder: (context, state) {
            final accepting = state is ReferralTermsAccepting;
            final error = state is ReferralNeedsTerms
                ? state.errorMessage
                : null;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ScrollableActionsLayout(
                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 16,
                  children: [
                    if (_loadFailed)
                      Text(s.legalDocumentLoadFailed)
                    else if (_markdown == null)
                      const Center(child: CupertinoActivityIndicator())
                    else
                      MarkdownBody(data: _markdown!),
                    if (error != null && error.isNotEmpty)
                      Text(
                        error,
                        style: TextStyle(color: RealUnitColors.status.red600),
                      ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _accepted,
                      onChanged: accepting
                          ? null
                          : (v) => setState(() => _accepted = v ?? false),
                      title: Text(s.referralTermsCheckbox),
                    ),
                  ],
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: AppFilledButton(
                      label: s.referralCreateInvite,
                      state: accepting
                          ? FilledButtonState.loading
                          : FilledButtonState.idle,
                      onPressed: _accepted && !accepting
                          ? () => context.read<ReferralCubit>().acceptTerms()
                          : null,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
