import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_bind_result_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/real_unit_referral_service.dart';
import 'package:realunit_wallet/setup/routing/referral_bind.dart';
import 'package:realunit_wallet/setup/routing/referral_pending_code.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockService extends Mock implements RealUnitReferralService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockService service;
  late GoRouter router;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    debugSetPendingReferralCodeSync(null);
    service = _MockService();
    await GetIt.instance.reset();
    GetIt.instance.registerSingleton<RealUnitReferralService>(service);
    router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SizedBox()),
      ],
    );
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  test('keeps the stashed code when bind fails', () async {
    await stashPendingReferralCode('AB12CD');
    when(() => service.bind(code: 'AB12CD')).thenThrow(
      const ApiException(code: 'UNAVAILABLE', message: 'down'),
    );

    await bindPendingReferralCode(router);

    expect(await peekPendingReferralCode(), 'AB12CD');
    verify(() => service.bind(code: 'AB12CD')).called(1);
  });

  test('clears the stash after a successful bind', () async {
    await stashPendingReferralCode('AB12CD');
    when(() => service.bind(code: 'AB12CD')).thenAnswer(
      (_) async => const ReferralBindResultDto(kind: 'Invite'),
    );

    await bindPendingReferralCode(router);

    expect(await peekPendingReferralCode(), isNull);
    verify(() => service.bind(code: 'AB12CD')).called(1);
    expect(router.state.uri.path, '/');
  });
}
