import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_created_invite_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_summary_dto.dart';
import 'package:realunit_wallet/screens/referral/cubit/referral_cubit.dart';
import 'package:realunit_wallet/screens/referral/referral_create_page.dart';
import 'package:realunit_wallet/styles/themes.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';

class _MockReferralCubit extends MockCubit<ReferralState>
    implements ReferralCubit {}

const _summary = ReferralSummaryDto(
  eligible: true,
  termsAccepted: true,
  openCount: 0,
  creditedCount: 0,
  realuSum: 0,
  chfSum: 0,
);

void main() {
  late _MockReferralCubit cubit;

  setUp(() {
    cubit = _MockReferralCubit();
  });

  testWidgets('after create, copy and share actions are shown with the API URL', (
    tester,
  ) async {
    const created = ReferralCreatedInviteDto(
      code: 'AB12CD',
      url: 'https://realunit.app/invite/AB12CD',
      guestName: 'Alice',
    );
    when(() => cubit.state).thenReturn(
      ReferralInviteCreated(summary: _summary, invite: created),
    );
    whenListen(
      cubit,
      const Stream<ReferralState>.empty(),
      initialState: ReferralInviteCreated(summary: _summary, invite: created),
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
          child: const ReferralCreateView(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Deine Einladung für Alice'), findsOneWidget);
    expect(find.text('https://realunit.app/invite/AB12CD'), findsOneWidget);
    expect(find.text('Einladungslink kopieren'), findsOneWidget);
    expect(find.text('Einladungslink versenden'), findsOneWidget);
  });

  testWidgets('copy writes the invite URL to the clipboard', (tester) async {
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

    const created = ReferralCreatedInviteDto(
      code: 'AB12CD',
      url: 'https://realunit.app/invite/AB12CD',
      guestName: 'Alice',
    );
    when(() => cubit.state).thenReturn(
      ReferralInviteCreated(summary: _summary, invite: created),
    );
    whenListen(
      cubit,
      const Stream<ReferralState>.empty(),
      initialState: ReferralInviteCreated(summary: _summary, invite: created),
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
          child: const ReferralCreateView(),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Einladungslink kopieren'));
    await tester.pump();

    expect(copied, 'https://realunit.app/invite/AB12CD');
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

    const created = ReferralCreatedInviteDto(
      code: 'AB12CD',
      url: 'https://realunit.app/invite/AB12CD',
      guestName: 'Alice',
      copyText: 'Hey Alice, Björn lädt dich ein: https://realunit.app/invite/AB12CD',
    );
    when(() => cubit.state).thenReturn(
      ReferralInviteCreated(summary: _summary, invite: created),
    );
    whenListen(
      cubit,
      const Stream<ReferralState>.empty(),
      initialState: ReferralInviteCreated(summary: _summary, invite: created),
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
          child: const ReferralCreateView(),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Einladungslink versenden'));
    await tester.pump();

    expect(
      shared,
      'Hey Alice, Björn lädt dich ein: https://realunit.app/invite/AB12CD',
    );
  });

  testWidgets('failure offers retry that reloads the summary', (tester) async {
    when(() => cubit.state).thenReturn(const ReferralFailure(message: 'down'));
    whenListen(
      cubit,
      const Stream<ReferralState>.empty(),
      initialState: const ReferralFailure(message: 'down'),
    );
    when(() => cubit.load()).thenAnswer((_) async {});
    when(() => cubit.openCreate()).thenReturn(null);

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
          child: const ReferralCreateView(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('down'), findsOneWidget);
    await tester.tap(find.byType(AppFilledButton));
    await tester.pump();
    await tester.pump();
    verify(() => cubit.load()).called(1);
    verify(() => cubit.openCreate()).called(1);
  });

  testWidgets('shows the API error on the name-entry form', (tester) async {
    when(() => cubit.state).thenReturn(
      ReferralCreateReady(summary: _summary, errorMessage: 'limit'),
    );
    whenListen(
      cubit,
      const Stream<ReferralState>.empty(),
      initialState: ReferralCreateReady(summary: _summary, errorMessage: 'limit'),
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
          child: const ReferralCreateView(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('limit'), findsOneWidget);
  });

  testWidgets('hides the form when the API gate is closed', (tester) async {
    when(() => cubit.state).thenReturn(const ReferralNotEligible());
    whenListen(
      cubit,
      const Stream<ReferralState>.empty(),
      initialState: const ReferralNotEligible(),
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
          child: const ReferralCreateView(),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.text(
        'Das Empfehlungsprogramm steht verifizierten Aktionären mit dem erforderlichen Bestand zur Verfügung.',
      ),
      findsOneWidget,
    );
    expect(find.byType(AppFilledButton), findsNothing);
  });

  testWidgets('does not create an invite when the guest name is empty', (tester) async {
    when(() => cubit.state).thenReturn(ReferralCreateReady(summary: _summary));
    whenListen(
      cubit,
      const Stream<ReferralState>.empty(),
      initialState: ReferralCreateReady(summary: _summary),
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
          child: const ReferralCreateView(),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Einladungslink erstellen'));
    await tester.pump();

    verifyNever(() => cubit.createInvite(guestName: any(named: 'guestName')));
  });

  testWidgets('needs-terms offers retry that reloads the summary', (tester) async {
    when(() => cubit.state).thenReturn(
      ReferralNeedsTerms(summary: _summary),
    );
    whenListen(
      cubit,
      const Stream<ReferralState>.empty(),
      initialState: ReferralNeedsTerms(summary: _summary),
    );
    when(() => cubit.load()).thenAnswer((_) async {});
    when(() => cubit.openCreate()).thenReturn(null);

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
          child: const ReferralCreateView(),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byType(AppFilledButton));
    await tester.pump();
    await tester.pump();
    verify(() => cubit.load()).called(1);
    verify(() => cubit.openCreate()).called(1);
  });

  testWidgets('app-bar back after create pops true so overview can refresh', (
    tester,
  ) async {
    const created = ReferralCreatedInviteDto(
      code: 'AB12CD',
      url: 'https://realunit.app/invite/AB12CD',
      guestName: 'Alice',
    );
    when(() => cubit.state).thenReturn(
      ReferralInviteCreated(summary: _summary, invite: created),
    );
    whenListen(
      cubit,
      const Stream<ReferralState>.empty(),
      initialState: ReferralInviteCreated(summary: _summary, invite: created),
    );

    bool? popped;
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => TextButton(
            onPressed: () async {
              popped = await context.push<bool>('/create');
            },
            child: const Text('go'),
          ),
        ),
        GoRoute(
          path: '/create',
          builder: (_, _) => BlocProvider<ReferralCubit>.value(
            value: cubit,
            child: const ReferralCreateView(),
          ),
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
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(popped, isTrue);
  });

  testWidgets('Done after create pops true so overview can refresh', (
    tester,
  ) async {
    const created = ReferralCreatedInviteDto(
      code: 'AB12CD',
      url: 'https://realunit.app/invite/AB12CD',
      guestName: 'Alice',
    );
    when(() => cubit.state).thenReturn(
      ReferralInviteCreated(summary: _summary, invite: created),
    );
    whenListen(
      cubit,
      const Stream<ReferralState>.empty(),
      initialState: ReferralInviteCreated(summary: _summary, invite: created),
    );

    bool? popped;
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => TextButton(
            onPressed: () async {
              popped = await context.push<bool>('/create');
            },
            child: const Text('go'),
          ),
        ),
        GoRoute(
          path: '/create',
          builder: (_, _) => BlocProvider<ReferralCubit>.value(
            value: cubit,
            child: const ReferralCreateView(),
          ),
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
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Erledigt'));
    await tester.pumpAndSettle();

    expect(popped, isTrue);
  });
}
