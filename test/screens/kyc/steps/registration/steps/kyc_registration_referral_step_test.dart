import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/cubits/registration_step/kyc_registration_step_cubit.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/steps/kyc_registration_referral_step.dart';
import 'package:realunit_wallet/setup/routing/referral_pending_code.dart';
import 'package:realunit_wallet/styles/themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockKycRegistrationStepCubit extends MockCubit<KycRegistrationStepState>
    implements KycRegistrationStepCubit {}

void main() {
  late _MockKycRegistrationStepCubit stepCubit;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    debugSetPendingReferralCodeSync(null);
    stepCubit = _MockKycRegistrationStepCubit();
    when(() => stepCubit.state).thenReturn(
      const KycRegistrationStepState(
        step: KycRegistrationStep.referral,
        steps: [
          KycRegistrationStep.referral,
          KycRegistrationStep.personal,
        ],
      ),
    );
  });

  testWidgets('skip and next both advance the registration cubit', (tester) async {
    final ctrl = TextEditingController();
    await tester.pumpWidget(
      MaterialApp(
        theme: realUnitTheme,
        locale: const Locale('de'),
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: Scaffold(
          body: BlocProvider<KycRegistrationStepCubit>.value(
            value: stepCubit,
            child: KycRegistrationReferralStep(referralCodeCtrl: ctrl),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Überspringen'), findsOneWidget);

    ctrl.text = 'NOPE';
    await tester.tap(find.text('Überspringen'));
    expect(ctrl.text, isEmpty);
    verify(() => stepCubit.next()).called(1);

    ctrl.text = 'AB12';
    await tester.tap(find.text('Weiter'));
    expect(ctrl.text, 'AB12');
    verify(() => stepCubit.next()).called(2);
  });

  testWidgets(
    'skip clears the field but leaves a deeplink stash for automatic takeover',
    (tester) async {
      await stashPendingReferralCode('AB12CD');
      final ctrl = TextEditingController(text: 'TYPED');
      await tester.pumpWidget(
        MaterialApp(
          theme: realUnitTheme,
          locale: const Locale('de'),
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          home: Scaffold(
            body: BlocProvider<KycRegistrationStepCubit>.value(
              value: stepCubit,
              child: KycRegistrationReferralStep(referralCodeCtrl: ctrl),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Überspringen'));
      expect(ctrl.text, isEmpty);
      expect(await peekPendingReferralCode(), 'AB12CD');
    },
  );
}
