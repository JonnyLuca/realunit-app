import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_summary_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_referral_service.dart';
import 'package:realunit_wallet/screens/referral/widgets/referral_entry_card.dart';
import 'package:realunit_wallet/styles/themes.dart';

class _MockService extends Mock implements RealUnitReferralService {}

void main() {
  late _MockService service;

  setUp(() {
    service = _MockService();
    GetIt.instance.registerSingleton<RealUnitReferralService>(service);
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  Future<void> pumpCard(WidgetTester tester) {
    return tester.pumpWidget(
      MaterialApp(
        theme: realUnitTheme,
        locale: const Locale('de'),
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: const Scaffold(body: ReferralEntryCard()),
      ),
    );
  }

  testWidgets('hides the dashboard card when the API gate is closed', (tester) async {
    when(() => service.getSummary()).thenAnswer(
      (_) async => const ReferralSummaryDto(
        eligible: false,
        termsAccepted: false,
        openCount: 0,
        creditedCount: 0,
        realuSum: 0,
        chfSum: 0,
      ),
    );

    await pumpCard(tester);
    await tester.pumpAndSettle();

    expect(find.text('Empfehlungen'), findsNothing);
  });

  testWidgets('shows the dashboard card when the API says eligible', (tester) async {
    when(() => service.getSummary()).thenAnswer(
      (_) async => const ReferralSummaryDto(
        eligible: true,
        termsAccepted: true,
        openCount: 0,
        creditedCount: 0,
        realuSum: 0,
        chfSum: 0,
      ),
    );

    await pumpCard(tester);
    await tester.pumpAndSettle();

    expect(find.text('Empfehlungen'), findsOneWidget);
    expect(find.text('Erhalte 20 REALU pro Weiterempfehlung'), findsOneWidget);
  });
}
