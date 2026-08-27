import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_summary_dto.dart';
import 'package:realunit_wallet/screens/referral/cubit/referral_cubit.dart';
import 'package:realunit_wallet/screens/referral/referral_terms_page.dart';
import 'package:realunit_wallet/styles/themes.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';

class _MockReferralCubit extends MockCubit<ReferralState>
    implements ReferralCubit {}

const _summary = ReferralSummaryDto(
  eligible: true,
  termsAccepted: false,
  openCount: 0,
  creditedCount: 0,
  realuSum: 0,
  chfSum: 0,
);

void main() {
  late _MockReferralCubit cubit;

  setUp(() {
    cubit = _MockReferralCubit();
    when(() => cubit.state).thenReturn(ReferralNeedsTerms(summary: _summary));
    whenListen(
      cubit,
      const Stream<ReferralState>.empty(),
      initialState: ReferralNeedsTerms(summary: _summary),
    );
    when(() => cubit.acceptTerms()).thenAnswer((_) async {});
  });

  testWidgets(
    'create-invite CTA stays disabled until the accepted-terms checkbox is on',
    (tester) async {
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
          home: BlocProvider<ReferralCubit>.value(
            value: cubit,
            child: const ReferralTermsPage(
              initialMarkdownContent: '# Teilnahmebedingungen',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.text('Teilnahmebedingungen Referral-Programm'),
        findsOneWidget,
      );

      final button = tester.widget<AppFilledButton>(find.byType(AppFilledButton));
      expect(button.onPressed, isNull);

      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();

      final enabled = tester.widget<AppFilledButton>(find.byType(AppFilledButton));
      expect(enabled.onPressed, isNotNull);

      await tester.tap(find.byType(AppFilledButton));
      await tester.pump();
      verify(() => cubit.acceptTerms()).called(1);
    },
  );
}
