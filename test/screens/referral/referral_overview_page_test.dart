import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
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
import 'package:realunit_wallet/setup/routing/routes/settings_routes.dart';
import 'package:realunit_wallet/styles/themes.dart';

class _MockReferralCubit extends MockCubit<ReferralState>
    implements ReferralCubit {}

void main() {
  late _MockReferralCubit cubit;

  setUp(() {
    cubit = _MockReferralCubit();
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
            builder: (_, _) => BlocProvider<ReferralCubit>.value(
              value: cubit,
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
}
