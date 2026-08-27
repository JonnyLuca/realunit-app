import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_invite_dto.dart';
import 'package:realunit_wallet/screens/referral/cubit/referral_cubit.dart';
import 'package:realunit_wallet/screens/referral/open_referral_create.dart';
import 'package:realunit_wallet/screens/referral/referral_share_text.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';
import 'package:realunit_wallet/widgets/scrollable_actions_layout.dart';
import 'package:share_plus/share_plus.dart';

class ReferralOverviewPage extends StatelessWidget {
  const ReferralOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.referralOverviewTitle)),
      body: SafeArea(
        child: BlocBuilder<ReferralCubit, ReferralState>(
          builder: (context, state) {
            if (state is ReferralLoading || state is ReferralInitial) {
              return const Center(child: CupertinoActivityIndicator());
            }
            if (state is ReferralFailure) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 16,
                    children: [
                      Text(state.message, textAlign: TextAlign.center),
                      AppFilledButton(
                        label: s.retry,
                        onPressed: () => context.read<ReferralCubit>().load(),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (state is! ReferralOverviewLoaded) {
              return const SizedBox.shrink();
            }

            final summary = state.summary;
            final openInvites = state.invites
                .where(
                  (invite) =>
                      invite.isOpen && invite.guestName.trim().isNotEmpty,
                )
                .toList();
            final chfFormat = NumberFormat.currency(
              locale: 'de_CH',
              symbol: 'CHF',
            );

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ScrollableActionsLayout(
                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 20,
                  children: [
                    BlocBuilder<SettingsBloc, SettingsState>(
                      builder: (context, settings) {
                        final chf = settings.hideAmounts
                            ? '***.**'
                            : chfFormat.format(summary.chfSum);
                        return _TotalReceivedTile(
                          realu: summary.realuSum,
                          hideAmounts: settings.hideAmounts,
                          chfLabel: s.referralChfAtSharePrice(
                            chf,
                            summary.sharePriceLabel ?? s.referralSharePrice,
                          ),
                          title: s.referralTotalReceived,
                        );
                      },
                    ),
                    Row(
                      spacing: 12,
                      children: [
                        Expanded(
                          child: _CountTile(
                            label: s.referralStatusOpen,
                            count: summary.openCount,
                          ),
                        ),
                        Expanded(
                          child: _CountTile(
                            label: s.referralStatusCredited,
                            count: summary.creditedCount,
                          ),
                        ),
                      ],
                    ),
                    for (final invite in openInvites)
                      _OpenInviteTile(invite: invite),
                    if (summary.openCount > 0 && openInvites.isEmpty)
                      AppFilledButton(
                        label: s.retry,
                        variant: FilledButtonVariant.secondary,
                        onPressed: () =>
                            context.read<ReferralCubit>().reloadInvites(),
                      ),
                    Text(
                      s.referralOpenInvitesExpire,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: RealUnitColors.neutral500,
                      ),
                    ),
                    Text(
                      s.referralOverviewHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: RealUnitColors.neutral500,
                      ),
                    ),
                  ],
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: AppFilledButton(
                      label: s.referralCreateInvite,
                      onPressed: () => openReferralCreateAndRefresh(context),
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

class _TotalReceivedTile extends StatelessWidget {
  final num realu;
  final bool hideAmounts;
  final String chfLabel;
  final String title;

  const _TotalReceivedTile({
    required this.realu,
    required this.hideAmounts,
    required this.chfLabel,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RealUnitColors.brand700,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: RealUnitColors.realUnitBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            hideAmounts ? '*** REALU' : '${realu.toStringAsFixed(0)} REALU',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            chfLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: RealUnitColors.neutral500,
            ),
          ),
        ],
      ),
    );
  }
}

class _OpenInviteTile extends StatelessWidget {
  final ReferralInviteDto invite;

  const _OpenInviteTile({required this.invite});

  String _shareText(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    return referralShareText(
      fromApi: invite.copyTextForLocale(lang),
      guestName: invite.guestName,
      url: invite.url,
      fallback: S.of(context).referralShareText,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: RealUnitColors.neutral200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Text(
            s.referralYourInviteFor(invite.guestName),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SelectableText(
            invite.url,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: RealUnitColors.realUnitBlue,
            ),
          ),
          AppFilledButton(
            label: s.referralCopyInviteLink,
            variant: FilledButtonVariant.secondary,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: invite.url));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s.copyClipboard)),
                );
              }
            },
          ),
          AppFilledButton(
            label: s.referralShareInviteLink,
            onPressed: () {
              final box = context.findRenderObject() as RenderBox?;
              Share.share(
                _shareText(context),
                sharePositionOrigin: box == null
                    ? const Rect.fromLTWH(0, 0, 1, 1)
                    : box.localToGlobal(Offset.zero) & box.size,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CountTile extends StatelessWidget {
  final String label;
  final int count;

  const _CountTile({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: RealUnitColors.neutral200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Text(
            '$count',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: RealUnitColors.neutral500),
          ),
        ],
      ),
    );
  }
}
