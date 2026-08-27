import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  testWidgets('failure offers retry that reloads the summary', (tester) async {
    when(() => cubit.state).thenReturn(const ReferralFailure(message: 'down'));
    whenListen(
      cubit,
      const Stream<ReferralState>.empty(),
      initialState: const ReferralFailure(message: 'down'),
    );
    when(() => cubit.load()).thenAnswer((_) async {});

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
    verify(() => cubit.load()).called(1);
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
}
