import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_created_invite_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_summary_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_referral_service.dart';
import 'package:realunit_wallet/screens/referral/cubit/referral_cubit.dart';
import 'package:realunit_wallet/screens/referral/referral_limits.dart';

class _MockService extends Mock implements RealUnitReferralService {}

const _eligible = ReferralSummaryDto(
  eligible: true,
  termsAccepted: true,
  openCount: 1,
  creditedCount: 0,
  realuSum: 0,
  chfSum: 0,
);

const _needsTerms = ReferralSummaryDto(
  eligible: true,
  termsAccepted: false,
  openCount: 0,
  creditedCount: 0,
  realuSum: 0,
  chfSum: 0,
);

void main() {
  late _MockService service;

  setUp(() {
    service = _MockService();
  });

  blocTest<ReferralCubit, ReferralState>(
    'load emits not-eligible when the API gate is closed',
    build: () {
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
      return ReferralCubit(service);
    },
    act: (cubit) => cubit.load(),
    expect: () => const [
      ReferralLoading(),
      ReferralNotEligible(),
    ],
  );

  blocTest<ReferralCubit, ReferralState>(
    'load emits needs-terms when eligible but terms are not accepted',
    build: () {
      when(() => service.getSummary()).thenAnswer((_) async => _needsTerms);
      return ReferralCubit(service);
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      const ReferralLoading(),
      ReferralNeedsTerms(summary: _needsTerms),
    ],
  );

  blocTest<ReferralCubit, ReferralState>(
    'load emits overview when eligible and terms accepted',
    build: () {
      when(() => service.getSummary()).thenAnswer((_) async => _eligible);
      when(() => service.getInvites()).thenAnswer((_) async => []);
      return ReferralCubit(service);
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      const ReferralLoading(),
      ReferralOverviewLoaded(summary: _eligible, invites: const []),
    ],
  );

  blocTest<ReferralCubit, ReferralState>(
    'acceptTerms posts acceptance then loads overview',
    build: () {
      when(() => service.acceptTerms()).thenAnswer((_) async {});
      when(() => service.getSummary()).thenAnswer((_) async => _eligible);
      when(() => service.getInvites()).thenAnswer((_) async => []);
      return ReferralCubit(service);
    },
    seed: () => ReferralNeedsTerms(summary: _needsTerms),
    act: (cubit) => cubit.acceptTerms(),
    expect: () => [
      ReferralTermsAccepting(summary: _needsTerms),
      ReferralOverviewLoaded(summary: _eligible, invites: const []),
    ],
  );

  blocTest<ReferralCubit, ReferralState>(
    'acceptTerms returns to the checkbox with the API error',
    build: () {
      when(() => service.acceptTerms()).thenThrow(
        const ApiException(code: 'FAILED', message: 'nope'),
      );
      return ReferralCubit(service);
    },
    seed: () => ReferralNeedsTerms(summary: _needsTerms),
    act: (cubit) => cubit.acceptTerms(),
    expect: () => [
      ReferralTermsAccepting(summary: _needsTerms),
      ReferralNeedsTerms(summary: _needsTerms, errorMessage: 'nope'),
    ],
  );

  blocTest<ReferralCubit, ReferralState>(
    'refreshOverview reloads counts after a new invite',
    build: () {
      when(() => service.getSummary()).thenAnswer((_) async => _eligible);
      when(() => service.getInvites()).thenAnswer((_) async => []);
      return ReferralCubit(service);
    },
    seed: () => ReferralInviteCreated(
      summary: _eligible,
      invite: const ReferralCreatedInviteDto(
        code: 'AB12',
        url: 'https://realunit.app/invite/AB12',
        guestName: 'Alice',
      ),
    ),
    act: (cubit) => cubit.refreshOverview(),
    expect: () => [
      ReferralOverviewLoaded(summary: _eligible, invites: const []),
    ],
  );

  blocTest<ReferralCubit, ReferralState>(
    'createInvite emits the created invite from the API',
    build: () {
      when(() => service.createInvite(guestName: 'Alice')).thenAnswer(
        (_) async => const ReferralCreatedInviteDto(
          code: 'AB12',
          url: 'https://realunit.app/invite/AB12',
          guestName: 'Alice',
        ),
      );
      return ReferralCubit(service);
    },
    seed: () => ReferralCreateReady(summary: _eligible),
    act: (cubit) => cubit.createInvite(guestName: 'Alice'),
    expect: () => [
      ReferralCreating(summary: _eligible, guestName: 'Alice'),
      ReferralInviteCreated(
        summary: _eligible,
        invite: const ReferralCreatedInviteDto(
          code: 'AB12',
          url: 'https://realunit.app/invite/AB12',
          guestName: 'Alice',
        ),
      ),
    ],
  );

  blocTest<ReferralCubit, ReferralState>(
    'createInvite surfaces the API error on the name-entry form',
    build: () {
      when(() => service.createInvite(guestName: 'Alice')).thenThrow(
        const ApiException(code: 'QUOTA', message: 'limit'),
      );
      return ReferralCubit(service);
    },
    seed: () => ReferralCreateReady(summary: _eligible),
    act: (cubit) => cubit.createInvite(guestName: 'Alice'),
    expect: () => [
      ReferralCreating(summary: _eligible, guestName: 'Alice'),
      ReferralCreateReady(summary: _eligible, errorMessage: 'limit'),
    ],
  );

  blocTest<ReferralCubit, ReferralState>(
    'openCreate moves from overview to the name-entry form',
    build: () => ReferralCubit(service),
    seed: () => ReferralOverviewLoaded(summary: _eligible, invites: const []),
    act: (cubit) => cubit.openCreate(),
    expect: () => [
      ReferralCreateReady(summary: _eligible),
    ],
  );

  blocTest<ReferralCubit, ReferralState>(
    'openCreate moves from a created invite back to the name-entry form',
    build: () => ReferralCubit(service),
    seed: () => ReferralInviteCreated(
      summary: _eligible,
      invite: const ReferralCreatedInviteDto(
        code: 'AB12',
        url: 'https://realunit.app/invite/AB12',
        guestName: 'Alice',
      ),
    ),
    act: (cubit) => cubit.openCreate(),
    expect: () => [
      ReferralCreateReady(summary: _eligible),
    ],
  );

  blocTest<ReferralCubit, ReferralState>(
    'acceptTerms still shows overview when the invite list is down',
    build: () {
      when(() => service.acceptTerms()).thenAnswer((_) async {});
      when(() => service.getSummary()).thenAnswer((_) async => _eligible);
      when(() => service.getInvites()).thenThrow(
        const ApiException(code: 'SERVER_ERROR', message: 'invites down'),
      );
      return ReferralCubit(service);
    },
    seed: () => ReferralNeedsTerms(summary: _needsTerms),
    act: (cubit) => cubit.acceptTerms(),
    expect: () => [
      ReferralTermsAccepting(summary: _needsTerms),
      ReferralOverviewLoaded(summary: _eligible, invites: const []),
    ],
  );

  blocTest<ReferralCubit, ReferralState>(
    'load shows overview counts when the invite list is down',
    build: () {
      when(() => service.getSummary()).thenAnswer((_) async => _eligible);
      when(() => service.getInvites()).thenThrow(
        const ApiException(code: 'SERVER_ERROR', message: 'invites down'),
      );
      return ReferralCubit(service);
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      const ReferralLoading(),
      ReferralOverviewLoaded(summary: _eligible, invites: const []),
    ],
  );

  blocTest<ReferralCubit, ReferralState>(
    'refreshOverview returns to terms when the API withdraws acceptance',
    build: () {
      when(() => service.getSummary()).thenAnswer((_) async => _needsTerms);
      return ReferralCubit(service);
    },
    seed: () => ReferralOverviewLoaded(summary: _eligible, invites: const []),
    act: (cubit) => cubit.refreshOverview(),
    expect: () => [
      ReferralNeedsTerms(summary: _needsTerms),
    ],
  );

  blocTest<ReferralCubit, ReferralState>(
    'acceptTerms hides the programme when the refreshed gate is closed',
    build: () {
      when(() => service.acceptTerms()).thenAnswer((_) async {});
      when(() => service.getSummary()).thenAnswer(
        (_) async => const ReferralSummaryDto(
          eligible: false,
          termsAccepted: true,
          openCount: 0,
          creditedCount: 0,
          realuSum: 0,
          chfSum: 0,
        ),
      );
      return ReferralCubit(service);
    },
    seed: () => ReferralNeedsTerms(summary: _needsTerms),
    act: (cubit) => cubit.acceptTerms(),
    expect: () => [
      ReferralTermsAccepting(summary: _needsTerms),
      const ReferralNotEligible(),
    ],
  );

  blocTest<ReferralCubit, ReferralState>(
    'refreshOverview hides the programme when the API gate closes',
    build: () {
      when(() => service.getSummary()).thenAnswer(
        (_) async => const ReferralSummaryDto(
          eligible: false,
          termsAccepted: true,
          openCount: 0,
          creditedCount: 0,
          realuSum: 0,
          chfSum: 0,
        ),
      );
      return ReferralCubit(service);
    },
    seed: () => ReferralOverviewLoaded(summary: _eligible, invites: const []),
    act: (cubit) => cubit.refreshOverview(),
    expect: () => const [ReferralNotEligible()],
  );

  blocTest<ReferralCubit, ReferralState>(
    'createInvite truncates a guest name to the field cap',
    build: () {
      when(
        () => service.createInvite(
          guestName: 'A' * maxReferralGuestNameLength,
        ),
      ).thenAnswer(
        (_) async => ReferralCreatedInviteDto(
          code: 'AB12',
          url: 'https://realunit.app/invite/AB12',
          guestName: 'A' * maxReferralGuestNameLength,
        ),
      );
      return ReferralCubit(service);
    },
    seed: () => ReferralCreateReady(summary: _eligible),
    act: (cubit) => cubit.createInvite(guestName: 'A' * 120),
    expect: () => [
      ReferralCreating(
        summary: _eligible,
        guestName: 'A' * maxReferralGuestNameLength,
      ),
      ReferralInviteCreated(
        summary: _eligible,
        invite: ReferralCreatedInviteDto(
          code: 'AB12',
          url: 'https://realunit.app/invite/AB12',
          guestName: 'A' * maxReferralGuestNameLength,
        ),
      ),
    ],
    verify: (_) {
      verify(
        () => service.createInvite(
          guestName: 'A' * maxReferralGuestNameLength,
        ),
      ).called(1);
    },
  );

  blocTest<ReferralCubit, ReferralState>(
    'createInvite ignores a blank guest name',
    build: () => ReferralCubit(service),
    seed: () => ReferralCreateReady(summary: _eligible),
    act: (cubit) => cubit.createInvite(guestName: '   '),
    expect: () => <ReferralState>[],
    verify: (_) {
      verifyNever(() => service.createInvite(guestName: any(named: 'guestName')));
    },
  );

  blocTest<ReferralCubit, ReferralState>(
    'load surfaces API errors',
    build: () {
      when(() => service.getSummary()).thenThrow(
        const ApiException(code: 'SERVER_ERROR', message: 'boom'),
      );
      return ReferralCubit(service);
    },
    act: (cubit) => cubit.load(),
    expect: () => const [
      ReferralLoading(),
      ReferralFailure(message: 'boom'),
    ],
  );
}
