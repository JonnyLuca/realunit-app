import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_summary_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_referral_service.dart';
import 'package:realunit_wallet/screens/referral/cubit/referral_eligibility_cubit.dart';

class _MockService extends Mock implements RealUnitReferralService {}

void main() {
  late _MockService service;

  setUp(() {
    service = _MockService();
  });

  blocTest<ReferralEligibilityCubit, ReferralEligibilityState>(
    'emits eligible from the API gate 1:1',
    build: () {
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
      return ReferralEligibilityCubit(service);
    },
    act: (cubit) => cubit.load(),
    expect: () => const [
      ReferralEligibilityLoading(),
      ReferralEligibilityLoaded(eligible: true),
    ],
  );

  blocTest<ReferralEligibilityCubit, ReferralEligibilityState>(
    'hides the entry when the API call fails',
    build: () {
      when(() => service.getSummary()).thenThrow(Exception('down'));
      return ReferralEligibilityCubit(service);
    },
    act: (cubit) => cubit.load(),
    expect: () => const [
      ReferralEligibilityLoading(),
      ReferralEligibilityLoaded(eligible: false),
    ],
  );
}
