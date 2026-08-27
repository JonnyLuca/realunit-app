import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_created_invite_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_summary_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_referral_service.dart';
import 'package:realunit_wallet/screens/referral/cubit/referral_cubit.dart';

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
