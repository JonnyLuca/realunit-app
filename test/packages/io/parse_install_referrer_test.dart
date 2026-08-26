import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/io/parse_install_referrer.dart';

void main() {
  group('parseInviteCodeFromReferrer', () {
    test('reads invite=<code> as Play delivers it', () {
      expect(parseInviteCodeFromReferrer('invite=AB12CD'), 'AB12CD');
    });

    test('decodes a percent-encoded referrer', () {
      expect(parseInviteCodeFromReferrer('invite%3DAB12CD'), 'AB12CD');
    });

    test('keeps the code when extra utm fields are present', () {
      expect(
        parseInviteCodeFromReferrer('utm_source=google-play&invite=EVT1'),
        'EVT1',
      );
    });

    test('returns null for missing, empty, or unrelated referrers', () {
      expect(parseInviteCodeFromReferrer(null), isNull);
      expect(parseInviteCodeFromReferrer(''), isNull);
      expect(parseInviteCodeFromReferrer('utm_source=google-play'), isNull);
      expect(parseInviteCodeFromReferrer('invite='), isNull);
      expect(parseInviteCodeFromReferrer('invite=   '), isNull);
    });

    test('caps at 256 characters', () {
      final long = 'x' * 300;
      expect(parseInviteCodeFromReferrer('invite=$long')!.length, 256);
    });
  });
}
