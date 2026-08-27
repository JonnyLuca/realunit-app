// Responsive matrix gate for referral sticky-CTA pages.
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
import 'package:realunit_wallet/screens/referral/referral_create_page.dart';
import 'package:realunit_wallet/screens/referral/referral_overview_page.dart';
import 'package:realunit_wallet/screens/referral/referral_terms_page.dart';
import 'package:realunit_wallet/setup/routing/routes/settings_routes.dart';
import 'package:realunit_wallet/styles/themes.dart';
import 'package:realunit_wallet/widgets/buttons/app_filled_button.dart';

import '../../helper/helper.dart';

class _MockReferralCubit extends MockCubit<ReferralState>
    implements ReferralCubit {}

const _summary = ReferralSummaryDto(
  eligible: true,
  termsAccepted: true,
  openCount: 2,
  creditedCount: 1,
  realuSum: 20,
  chfSum: 246.5,
);

final _openInvite = ReferralInviteDto(
  id: 1,
  code: 'AAAA',
  url: 'https://realunit.app/invite/AAAA',
  guestName: 'Alice',
  status: 'Open',
  created: DateTime.utc(2026, 8, 1),
);

Future<void> _pumpScreen(
  WidgetTester tester,
  Widget widget,
  MediaQueryData mediaQuery,
) async {
  await tester.binding.setSurfaceSize(mediaQuery.size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => widget,
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
    MediaQuery(
      data: mediaQuery,
      child: MaterialApp.router(
        theme: realUnitTheme,
        locale: const Locale('de'),
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  late _MockReferralCubit cubit;

  setUp(() {
    cubit = _MockReferralCubit();
    when(() => cubit.acceptTerms()).thenAnswer((_) async {});
    when(() => cubit.load()).thenAnswer((_) async {});
  });

  group('ReferralTermsPage responsive matrix', () {
    for (final cell in kFullResponsiveMatrix) {
      testWidgets(cell.id, (tester) async {
        when(() => cubit.state).thenReturn(
          ReferralNeedsTerms(summary: _summary),
        );
        whenListen(
          cubit,
          const Stream<ReferralState>.empty(),
          initialState: ReferralNeedsTerms(summary: _summary),
        );
        await withTargetPlatform(cell.device.platform, () async {
          await expectNoLayoutOverflow(
            tester,
            () async {
              await _pumpScreen(
                tester,
                BlocProvider<ReferralCubit>.value(
                  value: cubit,
                  child: const ReferralTermsPage(
                    initialMarkdownContent: '# Teilnahmebedingungen\n\nText.',
                  ),
                ),
                cell.mediaQuery,
              );
            },
            reason: 'overflow on ${cell.label}',
          );

          await expectFullyTappable(
            tester,
            find.byType(AppFilledButton),
            within: find.byType(ReferralTermsPage),
            reason: '${cell.label}: terms CTA not tappable',
          );
        });
      });
    }
  });

  group('ReferralOverviewPage responsive matrix', () {
    for (final cell in kFullResponsiveMatrix) {
      testWidgets(cell.id, (tester) async {
        when(() => cubit.state).thenReturn(
          ReferralOverviewLoaded(summary: _summary, invites: [_openInvite]),
        );
        whenListen(
          cubit,
          const Stream<ReferralState>.empty(),
          initialState: ReferralOverviewLoaded(
            summary: _summary,
            invites: [_openInvite],
          ),
        );
        await withTargetPlatform(cell.device.platform, () async {
          await expectNoLayoutOverflow(
            tester,
            () async {
              await _pumpScreen(
                tester,
                BlocProvider<ReferralCubit>.value(
                  value: cubit,
                  child: const ReferralOverviewPage(),
                ),
                cell.mediaQuery,
              );
            },
            reason: 'overflow on ${cell.label}',
          );

          await expectFullyTappable(
            tester,
            find.byType(AppFilledButton),
            within: find.byType(ReferralOverviewPage),
            reason: '${cell.label}: overview CTA not tappable',
          );
        });
      });
    }
  });

  group('ReferralCreateView responsive matrix', () {
    for (final cell in kFullResponsiveMatrix) {
      testWidgets(cell.id, (tester) async {
        when(() => cubit.state).thenReturn(
          ReferralCreateReady(summary: _summary),
        );
        whenListen(
          cubit,
          const Stream<ReferralState>.empty(),
          initialState: ReferralCreateReady(summary: _summary),
        );
        await withTargetPlatform(cell.device.platform, () async {
          await expectNoLayoutOverflow(
            tester,
            () async {
              await _pumpScreen(
                tester,
                BlocProvider<ReferralCubit>.value(
                  value: cubit,
                  child: const ReferralCreateView(),
                ),
                cell.mediaQuery,
              );
            },
            reason: 'overflow on ${cell.label}',
          );

          await expectFullyTappable(
            tester,
            find.byType(AppFilledButton),
            within: find.byType(ReferralCreateView),
            reason: '${cell.label}: create CTA not tappable',
          );
        });
      });
    }
  });
}
