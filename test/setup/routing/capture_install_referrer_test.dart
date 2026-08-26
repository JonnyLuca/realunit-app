import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/io/install_referrer_port.dart';
import 'package:realunit_wallet/setup/routing/capture_install_referrer.dart';
import 'package:realunit_wallet/setup/routing/referral_pending_code.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakePort implements InstallReferrerPort {
  _FakePort(this.value, {this.throwing = false});

  final String? value;
  final bool throwing;
  int calls = 0;

  @override
  Future<String?> readInstallReferrer() async {
    calls += 1;
    if (throwing) throw StateError('channel down');
    return value;
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    debugSetPendingReferralCodeSync(null);
  });

  test('stashes the invite code from a Play referrer once', () async {
    final prefs = await SharedPreferences.getInstance();
    final port = _FakePort('invite=AB12CD');

    await captureInstallReferrer(prefs: prefs, port: port);
    expect(peekPendingReferralCodeSync(), 'AB12CD');
    expect(prefs.getBool(installReferrerConsumedKey), isTrue);

    await captureInstallReferrer(prefs: prefs, port: port);
    expect(port.calls, 1);
  });

  test('marks consumed when Play returns an empty referrer', () async {
    final prefs = await SharedPreferences.getInstance();
    final port = _FakePort('');

    await captureInstallReferrer(prefs: prefs, port: port);
    expect(peekPendingReferralCodeSync(), isNull);
    expect(prefs.getBool(installReferrerConsumedKey), isTrue);
  });

  test('does not consume on a channel failure so the next launch can retry', () async {
    final prefs = await SharedPreferences.getInstance();
    final port = _FakePort(null, throwing: true);

    await captureInstallReferrer(prefs: prefs, port: port);
    expect(prefs.getBool(installReferrerConsumedKey), isNot(true));
    expect(port.calls, 1);
  });
}
