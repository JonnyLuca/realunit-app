import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_bind_result_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_referral_service.dart';
import 'package:realunit_wallet/setup/routing/referral_bind.dart';
import 'package:realunit_wallet/setup/routing/referral_pending_code.dart';
import 'package:realunit_wallet/styles/themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockService extends Mock implements RealUnitReferralService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockService service;
  late GoRouter router;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    debugSetPendingReferralCodeSync(null);
    service = _MockService();
    await GetIt.instance.reset();
    GetIt.instance.registerSingleton<RealUnitReferralService>(service);
    router = GoRouter(
      navigatorKey: GlobalKey<NavigatorState>(),
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SizedBox()),
      ],
    );
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  test('keeps the stashed code when bind fails with a retryable error', () async {
    await stashPendingReferralCode('AB12CD');
    when(() => service.bind(code: 'AB12CD')).thenThrow(
      const ApiException(
        statusCode: 503,
        code: 'UNAVAILABLE',
        message: 'down',
      ),
    );

    await bindPendingReferralCode(router);

    expect(await peekPendingReferralCode(), 'AB12CD');
    verify(() => service.bind(code: 'AB12CD')).called(1);
  });

  test('keeps the stashed code when bind returns 401 or 429', () async {
    when(() => service.bind(code: 'AB12CD')).thenThrow(
      const ApiException(
        statusCode: 401,
        code: 'UNAUTHORIZED',
        message: 'auth',
      ),
    );
    await stashPendingReferralCode('AB12CD');
    await bindPendingReferralCode(router);
    expect(await peekPendingReferralCode(), 'AB12CD');

    when(() => service.bind(code: 'AB12CD')).thenThrow(
      const ApiException(
        statusCode: 429,
        code: 'RATE_LIMIT',
        message: 'slow down',
      ),
    );
    await bindPendingReferralCode(router);
    expect(await peekPendingReferralCode(), 'AB12CD');
    verify(() => service.bind(code: 'AB12CD')).called(2);
  });

  test('keeps the stashed code when bind returns 408', () async {
    await stashPendingReferralCode('AB12CD');
    when(() => service.bind(code: 'AB12CD')).thenThrow(
      const ApiException(
        statusCode: 408,
        code: 'TIMEOUT',
        message: 'slow',
      ),
    );

    await bindPendingReferralCode(router);

    expect(await peekPendingReferralCode(), 'AB12CD');
    verify(() => service.bind(code: 'AB12CD')).called(1);
  });

  test('keeps the stashed code when bind times out', () async {
    await stashPendingReferralCode('AB12CD');
    when(() => service.bind(code: 'AB12CD')).thenThrow(
      TimeoutException('bind'),
    );

    await bindPendingReferralCode(router);

    expect(await peekPendingReferralCode(), 'AB12CD');
    verify(() => service.bind(code: 'AB12CD')).called(1);
  });

  test('keeps the stash when bind hits an unmounted NestJS route', () async {
    await stashPendingReferralCode('AB12CD');
    when(() => service.bind(code: 'AB12CD')).thenThrow(
      const ApiException(
        statusCode: 404,
        code: 'UNKNOWN',
        message: 'Cannot POST /v1/realunit/referral/bind',
      ),
    );

    await bindPendingReferralCode(router);

    expect(await peekPendingReferralCode(), 'AB12CD');
    verify(() => service.bind(code: 'AB12CD')).called(1);
  });

  test('drops the stash on a 4xx business rejection', () async {
    await stashPendingReferralCode('AB12CD');
    when(() => service.bind(code: 'AB12CD')).thenThrow(
      const ApiException(
        statusCode: 409,
        code: 'ALREADY_BOUND',
        message: 'already bound',
      ),
    );

    await bindPendingReferralCode(router);

    expect(await peekPendingReferralCode(), isNull);
    verify(() => service.bind(code: 'AB12CD')).called(1);
  });

  test('drops the stash on a business 404 (code not found)', () async {
    await stashPendingReferralCode('NOPE');
    when(() => service.bind(code: 'NOPE')).thenThrow(
      const ApiException(
        statusCode: 404,
        code: 'NOT_FOUND',
        message: 'missing',
      ),
    );

    await bindPendingReferralCode(router);

    expect(await peekPendingReferralCode(), isNull);
  });

  test('does not bind the same stash twice concurrently', () async {
    await stashPendingReferralCode('AB12CD');
    final started = Completer<void>();
    final release = Completer<ReferralBindResultDto>();
    when(() => service.bind(code: 'AB12CD')).thenAnswer((_) async {
      started.complete();
      return release.future;
    });

    final first = bindPendingReferralCode(router);
    await started.future;
    await bindPendingReferralCode(router);
    release.complete(const ReferralBindResultDto(kind: 'Invite'));
    await first;

    verify(() => service.bind(code: 'AB12CD')).called(1);
    expect(await peekPendingReferralCode(), isNull);
  });

  test('clears the stash after a successful bind', () async {
    await stashPendingReferralCode('AB12CD');
    when(() => service.bind(code: 'AB12CD')).thenAnswer(
      (_) async => const ReferralBindResultDto(kind: 'Invite'),
    );

    await bindPendingReferralCode(router);

    expect(await peekPendingReferralCode(), isNull);
    verify(() => service.bind(code: 'AB12CD')).called(1);
    expect(router.state.uri.path, '/');
  });

  testWidgets(
    'shows the API campaign text after a promo bind without SettingsBloc',
    (tester) async {
      await stashPendingReferralCode('EVT1');
      when(() => service.bind(code: 'EVT1')).thenAnswer(
        (_) async => const ReferralBindResultDto(
          kind: 'Promo',
          campaignText: 'Mit dem Code EVT1 schenken wir dir 20 Token.',
        ),
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
      await tester.pumpAndSettle();

      final pending = bindPendingReferralCode(router);
      await tester.pump();
      await tester.pump();

      expect(find.text('Aktion'), findsOneWidget);
      expect(
        find.text('Mit dem Code EVT1 schenken wir dir 20 Token.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Schließen'));
      await tester.pumpAndSettle();
      await pending;
      expect(await peekPendingReferralCode(), isNull);
    },
  );

  testWidgets('shows campaignTextEn after a promo bind in English', (
    tester,
  ) async {
    await stashPendingReferralCode('EVT1');
    when(() => service.bind(code: 'EVT1')).thenAnswer(
      (_) async => const ReferralBindResultDto(
        kind: 'Promo',
        campaignText: 'DE Aktion',
        campaignTextEn: 'EN campaign from the API',
      ),
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: realUnitTheme,
        locale: const Locale('en'),
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    final pending = bindPendingReferralCode(router);
    await tester.pump();
    await tester.pump();

    expect(find.text('EN campaign from the API'), findsOneWidget);
    expect(find.text('DE Aktion'), findsNothing);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    await pending;
    expect(await peekPendingReferralCode(), isNull);
  });
}
