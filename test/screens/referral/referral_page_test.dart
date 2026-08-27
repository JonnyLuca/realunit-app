import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_summary_dto.dart';
import 'package:realunit_wallet/screens/referral/cubit/referral_cubit.dart';
import 'package:realunit_wallet/screens/referral/referral_page.dart';
import 'package:realunit_wallet/styles/themes.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';

class _MockReferralCubit extends MockCubit<ReferralState>
    implements ReferralCubit {}

void main() {
  late _MockReferralCubit cubit;

  setUp(() {
    cubit = _MockReferralCubit();
    when(() => cubit.load()).thenAnswer((_) async {});
  });

  Future<void> pumpGate(WidgetTester tester, ReferralState state) async {
    when(() => cubit.state).thenReturn(state);
    whenListen(
      cubit,
      const Stream<ReferralState>.empty(),
      initialState: state,
    );
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
          child: const ReferralGateView(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('hides the programme when the API gate is closed', (tester) async {
    await pumpGate(tester, const ReferralNotEligible());

    expect(
      find.text(
        'Das Empfehlungsprogramm steht verifizierten Aktionären mit dem erforderlichen Bestand zur Verfügung.',
      ),
      findsOneWidget,
    );
    expect(find.byType(AppFilledButton), findsNothing);
  });

  testWidgets('failure offers retry that reloads the summary', (tester) async {
    await pumpGate(tester, const ReferralFailure(message: 'down'));

    expect(find.text('down'), findsOneWidget);
    await tester.tap(find.byType(AppFilledButton));
    await tester.pump();
    verify(() => cubit.load()).called(1);
  });

  testWidgets('overview is shown for an eligible, terms-accepted summary', (
    tester,
  ) async {
    await pumpGate(
      tester,
      const ReferralOverviewLoaded(
        summary: ReferralSummaryDto(
          eligible: true,
          termsAccepted: true,
          openCount: 0,
          creditedCount: 0,
          realuSum: 0,
          chfSum: 0,
        ),
        invites: [],
      ),
    );

    expect(find.text('Deine Empfehlungen'), findsOneWidget);
    expect(find.text('Einladungslink erstellen'), findsOneWidget);
  });
}
