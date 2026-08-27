import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/referral_json_list.dart';

void main() {
  test('reads a bare JSON array of objects', () {
    expect(
      referralJsonList([
        {'id': 1},
        'skip',
        {'id': 2},
      ]),
      [
        {'id': 1},
        {'id': 2},
      ],
    );
  });

  test('unwraps invites, payouts, data, and items wrappers', () {
    expect(
      referralJsonList({
        'invites': [
          {'code': 'AB12'},
        ],
      }),
      [
        {'code': 'AB12'},
      ],
    );
    expect(
      referralJsonList({
        'payouts': [
          {'id': 9},
        ],
      }),
      [
        {'id': 9},
      ],
    );
    expect(
      referralJsonList({
        'data': [
          {'id': 1},
        ],
      }),
      [
        {'id': 1},
      ],
    );
    expect(
      referralJsonList({
        'items': [
          {'id': 2},
        ],
      }),
      [
        {'id': 2},
      ],
    );
  });

  test('unknown shapes yield an empty list', () {
    expect(referralJsonList(null), isEmpty);
    expect(referralJsonList('nope'), isEmpty);
    expect(referralJsonList({'count': 0}), isEmpty);
  });
}
