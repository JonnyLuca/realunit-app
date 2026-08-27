import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_summary_dto.dart';
import 'package:realunit_wallet/screens/referral/cubit/referral_cubit.dart';
import 'package:realunit_wallet/screens/referral/referral_page.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/setup/routing/routes/settings_routes.dart';
import 'package:realunit_wallet/styles/language.dart';
import 'package:realunit_wallet/styles/themes.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';

class _MockReferralCubit extends MockCubit<ReferralState>
    implements ReferralCubit {}

class _MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

void main() {
  late _MockReferralCubit cubit;
  late _MockSettingsBloc settings;

  setUp(() {
    cubit = _MockReferralCubit();
    when(() => cubit.load()).thenAnswer((_) async {});
    settings = _MockSettingsBloc();
    const settingsState = SettingsState(language: Language.de);
    when(() => settings.state).thenReturn(settingsState);
    whenListen(
      settings,
      const Stream<SettingsState>.empty(),
      initialState: settingsState,
    );
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
        home: MultiBlocProvider(
          providers: [
            BlocProvider<ReferralCubit>.value(value: cubit),
            BlocProvider<SettingsBloc>.value(value: settings),
          ],
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

  testWidgets('accepting terms opens the create-invite screen', (tester) async {
    const needs = ReferralSummaryDto(
      eligible: true,
      termsAccepted: false,
      openCount: 0,
      creditedCount: 0,
      realuSum: 0,
      chfSum: 0,
    );
    const eligible = ReferralSummaryDto(
      eligible: true,
      termsAccepted: true,
      openCount: 0,
      creditedCount: 0,
      realuSum: 0,
      chfSum: 0,
    );
    when(() => cubit.state).thenReturn(ReferralNeedsTerms(summary: needs));
    when(() => cubit.refreshOverview()).thenAnswer((_) async {});
    whenListen(
      cubit,
      Stream.fromIterable([
        const ReferralOverviewLoaded(summary: eligible, invites: []),
      ]),
      initialState: ReferralNeedsTerms(summary: needs),
    );

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => MultiBlocProvider(
            providers: [
              BlocProvider<ReferralCubit>.value(value: cubit),
              BlocProvider<SettingsBloc>.value(value: settings),
            ],
            child: const ReferralGate(),
          ),
          routes: [
            GoRoute(
              name: SettingsRoutes.referralCreate,
              path: 'create',
              builder: (_, _) => const Text('create-invite'),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        theme: realUnitTheme,
        locale: const Locale('de'),
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('create-invite'), findsOneWidget);
  });
}
