import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/referral/referral_share_text.dart';

void main() {
  String fallback(String guestName, String hostName, String url) =>
      'Hey $guestName, $hostName: $url';

  test('uses the API share text when present', () {
    expect(
      referralShareText(
        fromApi: 'Hey Alice, Björn lädt dich ein: https://realunit.app/invite/AB',
        guestName: 'Alice',
        url: 'https://realunit.app/invite/AB',
        fallback: fallback,
      ),
      'Hey Alice, Björn lädt dich ein: https://realunit.app/invite/AB',
    );
  });

  test('falls back when the API share text is blank', () {
    expect(
      referralShareText(
        fromApi: '  ',
        guestName: 'Alice',
        url: 'https://realunit.app/invite/AB',
        fallback: fallback,
      ),
      'Hey Alice, RealUnit: https://realunit.app/invite/AB',
    );
  });
}
