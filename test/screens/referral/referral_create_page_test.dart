import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/generated/i18n.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_created_invite_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_summary_dto.dart';
import 'package:realunit_wallet/screens/referral/cubit/referral_cubit.dart';
import 'package:realunit_wallet/screens/referral/referral_create_page.dart';
import 'package:realunit_wallet/styles/themes.dart';

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

    expect(find.text('https://realunit.app/invite/AB12CD'), findsOneWidget);
    expect(find.text('Einladungslink kopieren'), findsOneWidget);
    expect(find.text('Einladungslink versenden'), findsOneWidget);
  });
}
