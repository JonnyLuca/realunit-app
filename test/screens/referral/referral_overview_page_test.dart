import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_invite_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_summary_dto.dart';
import 'package:realunit_wallet/screens/referral/cubit/referral_cubit.dart';
import 'package:realunit_wallet/screens/referral/referral_overview_page.dart';
import 'package:realunit_wallet/screens/settings/bloc/settings_bloc.dart';
import 'package:realunit_wallet/setup/routing/routes/settings_routes.dart';
import 'package:realunit_wallet/styles/language.dart';
import 'package:realunit_wallet/styles/themes.dart';

class _MockReferralCubit extends MockCubit<ReferralState>
    implements ReferralCubit {}

class _MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

void main() {
  late _MockReferralCubit cubit;
  late _MockSettingsBloc settings;

  setUp(() {
    cubit = _MockReferralCubit();
    settings = _MockSettingsBloc();
    const settingsState = SettingsState(language: Language.de);
    when(() => settings.state).thenReturn(settingsState);
    whenListen(
      settings,
      const Stream<SettingsState>.empty(),
      initialState: settingsState,
    );
  });

  testWidgets(
    'shows counts, Aktienkurs, and copy/share for open invites only',
    (tester) async {
      const summary = ReferralSummaryDto(
        eligible: true,
        termsAccepted: true,
        openCount: 3,
        creditedCount: 2,
        realuSum: 40,
        chfSum: 512.4,
        sharePriceLabel: 'Aktienkurs',
      );
      final invites = [
        ReferralInviteDto(
          id: 1,
          code: 'AAAA',
          url: 'https://realunit.app/invite/AAAA',
          guestName: 'AliceShouldNotAppear',
          status: 'Open',
          created: DateTime.utc(2026, 8, 1),
        ),
        ReferralInviteDto(
          id: 2,
          code: 'BBBB',
          url: 'https://realunit.app/invite/BBBB',
          guestName: 'BobShouldNotAppear',
          status: 'Credited',
          created: DateTime.utc(2026, 8, 2),
        ),
      ];
      when(() => cubit.state).thenReturn(
        ReferralOverviewLoaded(summary: summary, invites: invites),
      );
      whenListen(
        cubit,
        const Stream<ReferralState>.empty(),
        initialState: ReferralOverviewLoaded(summary: summary, invites: invites),
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
              child: const ReferralOverviewPage(),
            ),
            routes: [
              GoRoute(
                name: SettingsRoutes.referralCreate,
                path: 'create',
                builder: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      );

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

      expect(find.text('3'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Offen'), findsOneWidget);
      expect(find.text('Gutgeschrieben'), findsOneWidget);
      expect(find.text('Deine Empfehlungen'), findsOneWidget);
      expect(find.text('INSGESAMT ERHALTEN'), findsOneWidget);
      expect(find.textContaining('Aktienkurs'), findsOneWidget);
      expect(find.text('Offene Einladungen verfallen nach 3 Monaten.'), findsOneWidget);
      expect(find.text('Deine Einladung für AliceShouldNotAppear'), findsOneWidget);
      expect(find.text('Einladungslink kopieren'), findsOneWidget);
      expect(find.text('Einladungslink versenden'), findsOneWidget);
      expect(find.text('BobShouldNotAppear'), findsNothing);
      expect(find.text('Bound'), findsNothing);
      expect(find.text('Verifiziert'), findsNothing);
    },
  );

  testWidgets('hides an open invite with a blank guest name', (tester) async {
    const summary = ReferralSummaryDto(
      eligible: true,
      termsAccepted: true,
      openCount: 1,
      creditedCount: 0,
      realuSum: 0,
      chfSum: 0,
    );
    final invites = [
      ReferralInviteDto(
        id: 1,
        code: 'AAAA',
        url: 'https://realunit.app/invite/AAAA',
        guestName: '   ',
        status: 'Open',
        created: DateTime.utc(2026, 8, 1),
      ),
    ];
    when(() => cubit.state).thenReturn(
      ReferralOverviewLoaded(summary: summary, invites: invites),
    );
    whenListen(
      cubit,
      const Stream<ReferralState>.empty(),
      initialState: ReferralOverviewLoaded(summary: summary, invites: invites),
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
            child: const ReferralOverviewPage(),
          ),
          routes: [
            GoRoute(
              name: SettingsRoutes.referralCreate,
              path: 'create',
              builder: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ],
    );

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

    expect(find.text('Einladungslink kopieren'), findsNothing);
    expect(find.textContaining('Deine Einladung für'), findsNothing);
  });

  testWidgets('copy writes the open invite URL to the clipboard', (tester) async {
    String? copied;
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String?;
      }
      return null;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });

    const summary = ReferralSummaryDto(
      eligible: true,
      termsAccepted: true,
      openCount: 1,
      creditedCount: 0,
      realuSum: 0,
      chfSum: 0,
    );
    final invites = [
      ReferralInviteDto(
        id: 1,
        code: 'AAAA',
        url: 'https://realunit.app/invite/AAAA',
        guestName: 'Alice',
        status: 'Open',
        created: DateTime.utc(2026, 8, 1),
      ),
    ];
    when(() => cubit.state).thenReturn(
      ReferralOverviewLoaded(summary: summary, invites: invites),
    );
    whenListen(
      cubit,
      const Stream<ReferralState>.empty(),
      initialState: ReferralOverviewLoaded(summary: summary, invites: invites),
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
            child: const ReferralOverviewPage(),
          ),
          routes: [
            GoRoute(
              name: SettingsRoutes.referralCreate,
              path: 'create',
              builder: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ],
    );

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
    await tester.tap(find.text('Einladungslink kopieren'));
    await tester.pump();

    expect(copied, 'https://realunit.app/invite/AAAA');
    expect(find.text('In die Zwischenablage kopiert'), findsOneWidget);
  });

  testWidgets('share uses the API copyText 1:1', (tester) async {
    String? shared;
    const channel = MethodChannel('dev.fluttercommunity.plus/share');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async {
        if (call.method == 'share') {
          final args = call.arguments;
          if (args is Map) {
            shared = args['text'] as String?;
          }
        }
        return '';
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
    });

    const summary = ReferralSummaryDto(
      eligible: true,
      termsAccepted: true,
      openCount: 1,
      creditedCount: 0,
      realuSum: 0,
      chfSum: 0,
    );
    final invites = [
      ReferralInviteDto(
        id: 1,
        code: 'AAAA',
        url: 'https://realunit.app/invite/AAAA',
        guestName: 'Alice',
        status: 'Open',
        created: DateTime.utc(2026, 8, 1),
        copyText: 'Hey Alice, Björn lädt dich ein: https://realunit.app/invite/AAAA',
      ),
    ];
    when(() => cubit.state).thenReturn(
      ReferralOverviewLoaded(summary: summary, invites: invites),
    );
    whenListen(
      cubit,
      const Stream<ReferralState>.empty(),
      initialState: ReferralOverviewLoaded(summary: summary, invites: invites),
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
            child: const ReferralOverviewPage(),
          ),
          routes: [
            GoRoute(
              name: SettingsRoutes.referralCreate,
              path: 'create',
              builder: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ],
    );

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
    await tester.tap(find.text('Einladungslink versenden'));
    await tester.pump();

    expect(
      shared,
      'Hey Alice, Björn lädt dich ein: https://realunit.app/invite/AAAA',
    );
  });

  testWidgets('hides received REALU and CHF when amounts are hidden', (tester) async {
    const hidden = SettingsState(language: Language.de, hideAmounts: true);
    when(() => settings.state).thenReturn(hidden);
    whenListen(
      settings,
      const Stream<SettingsState>.empty(),
      initialState: hidden,
    );

    const summary = ReferralSummaryDto(
      eligible: true,
      termsAccepted: true,
      openCount: 0,
      creditedCount: 0,
      realuSum: 40,
      chfSum: 512.4,
      sharePriceLabel: 'Aktienkurs',
    );
    when(() => cubit.state).thenReturn(
      const ReferralOverviewLoaded(summary: summary, invites: []),
    );
    whenListen(
      cubit,
      const Stream<ReferralState>.empty(),
      initialState: const ReferralOverviewLoaded(summary: summary, invites: []),
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
            child: const ReferralOverviewPage(),
          ),
          routes: [
            GoRoute(
              name: SettingsRoutes.referralCreate,
              path: 'create',
              builder: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ],
    );

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

    expect(find.text('40 REALU'), findsNothing);
    expect(find.text('*** REALU'), findsOneWidget);
    expect(find.textContaining('512'), findsNothing);
    expect(find.textContaining('***.**'), findsOneWidget);
  });
}
