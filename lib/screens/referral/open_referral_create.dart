import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:realunit_wallet/screens/referral/cubit/referral_cubit.dart';
import 'package:realunit_wallet/setup/routing/routes/settings_routes.dart';

/// Pushes the create-invite screen and reloads overview counts if an invite
/// was created. Used after terms accept and from the overview CTA so the
/// first invite is not missing from the open/credited tiles.
Future<void> openReferralCreateAndRefresh(BuildContext context) async {
  final created = await context.pushNamed<bool>(SettingsRoutes.referralCreate);
  if (created == true && context.mounted) {
    await context.read<ReferralCubit>().refreshOverview();
  }
}
