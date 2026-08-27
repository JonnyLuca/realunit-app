import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_code_lookup_dto.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/cubits/registration_step/kyc_registration_step_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/widgets/referral_code_field.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';
import 'package:realunit_wallet/widgets/buttons/app_text_button.dart';

/// Optional invite/promo code step (Bilddokumentation Entwurf 4).
/// Skip advances without requiring a code; the same field is used for both.
class KycRegistrationReferralStep extends StatelessWidget {
  final TextEditingController referralCodeCtrl;

  /// Injected in tests. Production lookup goes through [ReferralCodeField].
  final Future<ReferralCodeLookupDto> Function(String code)? lookup;

  const KycRegistrationReferralStep({
    super.key,
    required this.referralCodeCtrl,
    this.lookup,
  });

  void _advance(BuildContext context, {required bool skip}) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (skip) referralCodeCtrl.clear();
    context.read<KycRegistrationStepCubit>().next();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            ReferralCodeField(
              controller: referralCodeCtrl,
              lookup: lookup,
              showHeading: false,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: AppFilledButton(
                label: s.next,
                onPressed: () => _advance(context, skip: false),
              ),
            ),
            AppTextButton(
              label: s.skip,
              onPressed: () => _advance(context, skip: true),
            ),
          ],
        ),
      ),
    );
  }
}
