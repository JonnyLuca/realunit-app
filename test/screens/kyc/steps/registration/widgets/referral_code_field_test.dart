import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_code_lookup_dto.dart';
import 'package:realunit_wallet/screens/kyc/steps/registration/widgets/referral_code_field.dart';
import 'package:realunit_wallet/styles/themes.dart';

void main() {
  Future<void> pumpField(
    WidgetTester tester, {
    required TextEditingController controller,
    required Future<ReferralCodeLookupDto> Function(String code) lookup,
  }) {
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
        home: Scaffold(
          body: ReferralCodeField(controller: controller, lookup: lookup),
        ),
      ),
    );
  }

  testWidgets('shows invite recognition after a successful lookup', (tester) async {
    final ctrl = TextEditingController(text: 'AB12');
    await pumpField(
      tester,
      controller: ctrl,
      lookup: (_) async => const ReferralCodeLookupDto(
        kind: 'invite',
        inviterName: 'Björn',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Hast du einen Empfehlungscode?'), findsOneWidget);
    expect(find.textContaining('Einladung von Björn erkannt'), findsOneWidget);
  });

  testWidgets('shows the API campaign text in a dialog for a promo code', (
    tester,
  ) async {
    final ctrl = TextEditingController(text: 'EVT1');
    await pumpField(
      tester,
      controller: ctrl,
      lookup: (_) async => const ReferralCodeLookupDto(
        kind: 'promo',
        actionText: 'Mit dem Code EVT1 schenken wir dir 20 Token.',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Aktion'), findsOneWidget);
    expect(
      find.text('Mit dem Code EVT1 schenken wir dir 20 Token.'),
      findsNWidgets(2),
    );
  });

  testWidgets('shows invalid copy on a 404 lookup', (tester) async {
    final ctrl = TextEditingController(text: 'NOPE');
    await pumpField(
      tester,
      controller: ctrl,
      lookup: (_) async => throw const ApiException(
        statusCode: 404,
        code: 'NOT_FOUND',
        message: 'missing',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.text('Dieser Code ist ungültig oder abgelaufen.'),
      findsOneWidget,
    );
  });

  testWidgets('ignores a stale lookup after the field changes', (tester) async {
    final ctrl = TextEditingController(text: 'OLD1');
    var firstLookupStarted = false;
    await pumpField(
      tester,
      controller: ctrl,
      lookup: (code) async {
        if (code == 'OLD1') {
          firstLookupStarted = true;
          await Future<void>.delayed(const Duration(milliseconds: 800));
          return const ReferralCodeLookupDto(
            kind: 'invite',
            inviterName: 'Stale',
          );
        }
        return const ReferralCodeLookupDto(
          kind: 'invite',
          inviterName: 'Björn',
        );
      },
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(firstLookupStarted, isTrue);

    ctrl.text = 'NEW1';
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.textContaining('Einladung von Stale erkannt'), findsNothing);
    expect(find.textContaining('Einladung von Björn erkannt'), findsOneWidget);
  });

  testWidgets('a lookup timeout is not shown as an invalid code', (tester) async {
    final ctrl = TextEditingController(text: 'AB12');
    await pumpField(
      tester,
      controller: ctrl,
      lookup: (_) async => throw TimeoutException('lookup'),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.text('Dieser Code ist ungültig oder abgelaufen.'),
      findsNothing,
    );
    expect(ctrl.text, 'AB12');
  });
}
