import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/referral/cubit/referral_cubit.dart';
import 'package:realunit_wallet/setup/routing/routes/settings_routes.dart';
import 'package:realunit_wallet/styles/colors.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';
import 'package:realunit_wallet/widgets/scrollable_actions_layout.dart';

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
              return const Center(child: CircularProgressIndicator());
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
                    _TotalReceivedTile(
                      realu: summary.realuSum,
                      chfLabel: s.referralChfAtSharePrice(
                        chfFormat.format(summary.chfSum),
                        summary.sharePriceLabel ?? s.referralSharePrice,
                      ),
                      title: s.referralTotalReceived,
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
                      onPressed: () async {
                        final created = await context.pushNamed<bool>(
                          SettingsRoutes.referralCreate,
                        );
                        if (created == true && context.mounted) {
                          await context.read<ReferralCubit>().refreshOverview();
                        }
                      },
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
  final String chfLabel;
  final String title;

  const _TotalReceivedTile({
    required this.realu,
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
            '${realu.toStringAsFixed(0)} REALU',
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
