import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/screens/referral/format_frozen_chf.dart';

void main() {
  test('formats a frozen CHF amount to two decimals', () {
    expect(formatFrozenChfAmount('246.5'), '246.50');
    expect(formatFrozenChfAmount('20'), '20.00');
    expect(formatFrozenChfAmount('not-a-number'), 'not-a-number');
  });
}
