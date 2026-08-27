import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/models/transaction.dart';
import 'package:realunit_wallet/packages/utils/default_assets.dart';
import 'package:realunit_wallet/screens/dashboard/widgets/transaction_row.dart';
import 'package:realunit_wallet/styles/themes.dart';

void main() {
  testWidgets('shows whole REALU, date, and CHF frozen at credit', (tester) async {
    final tx = Transaction(
      height: 0,
      txId: 'referral-payout-7',
      chainId: realUnitAsset.chainId,
      senderAddress: '',
      receiverAddress: '0xabc',
      amount: BigInt.from(20),
      asset: realUnitAsset,
      type: TransactionTypes.referralPayout,
      note: '',
      data: '246.5',
      timestamp: DateTime.utc(2026, 8, 24, 10),
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
        home: Scaffold(
          body: ReferralPayoutTransactionRow(transaction: tx),
        ),
      ),
    );

    expect(find.text('Empfehlungsprämie'), findsOneWidget);
    expect(find.textContaining('246.5'), findsOneWidget);
    expect(find.textContaining('24.08.2026'), findsOneWidget);
  });
}
