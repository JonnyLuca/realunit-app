import 'package:flutter_test/flutter_test.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_bind_result_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_code_lookup_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_created_invite_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_invite_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_payout_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_summary_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_terms_dto.dart';

void main() {
  group('$ReferralSummaryDto.fromJson', () {
    test('parses the eligibility gate and running totals 1:1', () {
      final dto = ReferralSummaryDto.fromJson({
        'eligible': true,
        'termsAccepted': false,
        'minHolding': 70,
        'openCount': 2,
        'creditedCount': 1,
        'realuSum': 20,
        'chfSum': 246.5,
      });

      expect(dto.eligible, isTrue);
      expect(dto.termsAccepted, isFalse);
      expect(dto.minHolding, 70);
      expect(dto.openCount, 2);
      expect(dto.creditedCount, 1);
      expect(dto.realuSum, 20);
      expect(dto.chfSum, 246.5);
      expect(dto.sharePriceLabel, isNull);
    });

    test('coerces eligible and termsAccepted from 1/true strings', () {
      final dto = ReferralSummaryDto.fromJson({
        'eligible': 1,
        'termsAccepted': 'true',
        'openCount': 0,
        'creditedCount': 0,
        'realuSum': 0,
        'chfSum': 0,
      });
      expect(dto.eligible, isTrue);
      expect(dto.termsAccepted, isTrue);

      final closed = ReferralSummaryDto.fromJson({
        'eligible': 'false',
        'termsAccepted': 0,
        'openCount': 0,
        'creditedCount': 0,
        'realuSum': 0,
        'chfSum': 0,
      });
      expect(closed.eligible, isFalse);
      expect(closed.termsAccepted, isFalse);
    });

    test('reads counts and sums from numeric strings', () {
      final dto = ReferralSummaryDto.fromJson({
        'eligible': true,
        'termsAccepted': true,
        'minHolding': '70',
        'openCount': '2',
        'creditedCount': '1',
        'realuSum': '40',
        'chfSum': '512.4',
      });
      expect(dto.minHolding, 70);
      expect(dto.openCount, 2);
      expect(dto.creditedCount, 1);
      expect(dto.realuSum, 40);
      expect(dto.chfSum, 512.4);
    });

    test('renders sharePriceLabel 1:1 when the API sends it', () {
      final dto = ReferralSummaryDto.fromJson({
        'eligible': true,
        'termsAccepted': true,
        'openCount': 0,
        'creditedCount': 0,
        'realuSum': 0,
        'chfSum': 0,
        'sharePriceLabel': 'Aktienkurs',
      });
      expect(dto.sharePriceLabel, 'Aktienkurs');
      expect(dto.tileSharePriceLabel, 'Aktienkurs');
    });

    test('empty and NAV sharePriceLabel fall back for the tile', () {
      final empty = ReferralSummaryDto.fromJson({
        'eligible': true,
        'termsAccepted': true,
        'openCount': 0,
        'creditedCount': 0,
        'realuSum': 0,
        'chfSum': 0,
        'sharePriceLabel': '  ',
      });
      expect(empty.sharePriceLabel, isNull);
      expect(empty.tileSharePriceLabel, isNull);

      final nav = ReferralSummaryDto.fromJson({
        'eligible': true,
        'termsAccepted': true,
        'openCount': 0,
        'creditedCount': 0,
        'realuSum': 0,
        'chfSum': 0,
        'sharePriceLabel': 'aktueller NAV',
      });
      expect(nav.sharePriceLabel, 'aktueller NAV');
      expect(nav.tileSharePriceLabel, isNull);
    });
  });

  group('$ReferralTermsDto', () {
    test('EN falls back to DE markdown', () {
      final dto = ReferralTermsDto.fromJson({
        'version': '2026-08-14',
        'markdown': 'DE md',
      });
      expect(dto.textForLang('de'), 'DE md');
      expect(dto.textForLang('en'), 'DE md');
    });

    test('EN prefers markdownEn', () {
      final dto = ReferralTermsDto.fromJson({
        'version': '2026-08-14',
        'markdown': 'DE md',
        'markdownEn': 'EN md',
      });
      expect(dto.textForLang('en'), 'EN md');
    });

    test('EN ignores empty markdownEn and uses DE', () {
      final dto = ReferralTermsDto.fromJson({
        'version': '2026-08-14',
        'markdown': 'DE md',
        'markdownEn': '  ',
      });
      expect(dto.textForLang('en'), 'DE md');
    });

    test('DE ignores empty markdown and uses EN', () {
      final dto = ReferralTermsDto.fromJson({
        'version': '2026-08-14',
        'markdown': '  ',
        'markdownEn': 'EN md',
      });
      expect(dto.textForLang('de'), 'EN md');
    });
  });

  group('$ReferralBindResultDto', () {
    test('maps Promo campaign text 1:1 and prefers EN when asked', () {
      final dto = ReferralBindResultDto.fromJson({
        'kind': 'Promo',
        'campaignText': 'DE text',
        'campaignTextEn': 'EN text',
        'minBuyRealu': 200,
        'validUntil': '2026-09-07T00:00:00Z',
        'redemptionCap': 100,
      });

      expect(dto.isPromo, isTrue);
      expect(dto.isInvite, isFalse);
      expect(dto.minBuyRealu, 200);
      expect(dto.redemptionCap, 100);
      expect(dto.campaignTextForLocale('en'), 'EN text');
      expect(dto.campaignTextForLocale('de'), 'DE text');
    });

    test('reads minBuyRealu from a numeric string', () {
      final dto = ReferralBindResultDto.fromJson({
        'kind': 'Promo',
        'minBuyRealu': '250',
        'redemptionCap': '80',
      });
      expect(dto.minBuyRealu, 250);
      expect(dto.redemptionCap, 80);
    });

    test('promo minBuyRealu defaults to 200 when the API omits it', () {
      final dto = ReferralBindResultDto.fromJson({
        'kind': 'Promo',
        'campaignText': 'DE text',
      });
      expect(dto.minBuyRealu, 200);

      final invite = ReferralBindResultDto.fromJson({'kind': 'Invite'});
      expect(invite.minBuyRealu, isNull);
    });

    test('EN falls back to DE when campaignTextEn is absent', () {
      final dto = ReferralBindResultDto.fromJson({
        'kind': 'Invite',
        'campaignText': 'DE only',
      });

      expect(dto.isInvite, isTrue);
      expect(dto.campaignTextForLocale('en'), 'DE only');
    });

    test('EN falls back to DE when campaignTextEn is empty', () {
      final dto = ReferralBindResultDto.fromJson({
        'kind': 'Promo',
        'campaignText': 'DE only',
        'campaignTextEn': '',
      });
      expect(dto.campaignTextForLocale('en'), 'DE only');
    });

    test('EN prefers actionTextEn when campaignTextEn is empty', () {
      final dto = ReferralBindResultDto.fromJson({
        'kind': 'Promo',
        'campaignText': 'DE only',
        'campaignTextEn': '',
        'actionTextEn': 'EN action',
      });
      expect(dto.campaignTextForLocale('en'), 'EN action');
    });

    test('falls back to actionText and treats campaign copy without kind as promo', () {
      final dto = ReferralBindResultDto.fromJson({
        'actionText': 'Mit dem Code EVT1 schenken wir dir 20 Token.',
      });
      expect(dto.isPromo, isTrue);
      expect(
        dto.campaignTextForLocale('de'),
        'Mit dem Code EVT1 schenken wir dir 20 Token.',
      );
    });

    test('kind matching is case-insensitive', () {
      expect(
        ReferralBindResultDto.fromJson({'kind': 'promo'}).isPromo,
        isTrue,
      );
      expect(
        ReferralBindResultDto.fromJson({'kind': 'INVITE'}).isInvite,
        isTrue,
      );
    });
  });

  group('$ReferralInviteDto.fromJson', () {
    test('maps Open / Credited status flags', () {
      final open = ReferralInviteDto.fromJson({
        'id': 1,
        'code': 'AB12',
        'url': 'https://realunit.app/invite/AB12',
        'guestName': 'Alice',
        'status': 'Open',
        'created': '2026-08-24T10:00:00Z',
      });
      final credited = ReferralInviteDto.fromJson({
        'id': 2,
        'code': 'CD34',
        'url': 'https://realunit.app/invite/CD34',
        'guestName': 'Bob',
        'status': 'Credited',
        'created': '2026-08-24T10:00:00Z',
      });

      expect(open.isOpen, isTrue);
      expect(open.isCredited, isFalse);
      expect(credited.isCredited, isTrue);
      expect(open.copyTextForLocale('de'), isNull);
    });

    test('stringifies a numeric code and trims guestName', () {
      final dto = ReferralInviteDto.fromJson({
        'id': 1,
        'code': 12,
        'url': 'https://realunit.app/invite/12',
        'guestName': '  Alice  ',
        'status': 'Open',
        'created': '2026-08-24T10:00:00Z',
      });
      expect(dto.code, '12');
      expect(dto.guestName, 'Alice');
    });

    test('status matching is case-insensitive', () {
      expect(
        ReferralInviteDto.fromJson({
          'id': 1,
          'code': 'AB12',
          'url': 'https://realunit.app/invite/AB12',
          'guestName': 'Alice',
          'status': 'open',
          'created': '2026-08-24T10:00:00Z',
        }).isOpen,
        isTrue,
      );
      expect(
        ReferralInviteDto.fromJson({
          'id': 2,
          'code': 'CD34',
          'url': 'https://realunit.app/invite/CD34',
          'guestName': 'Bob',
          'status': 'CREDITED',
          'created': '2026-08-24T10:00:00Z',
        }).isCredited,
        isTrue,
      );
    });
  });

  group('$ReferralPayoutDto.fromJson', () {
    test('keeps the CHF value frozen at credit', () {
      final dto = ReferralPayoutDto.fromJson({
        'id': 9,
        'amount': 20,
        'chfValue': 246.5,
        'created': '2026-08-24T10:00:00Z',
        'kind': 'Invite',
        'status': 'Complete',
        'txHash': '0xabc',
      });

      expect(dto.amount, 20);
      expect(dto.chfValue, 246.5);
      expect(dto.txHash, '0xabc');
      expect(dto.isSettled, isTrue);
    });

    test('reads amount and frozen CHF when the API sends numeric strings', () {
      final dto = ReferralPayoutDto.fromJson({
        'id': '9',
        'amount': '20',
        'chfValue': '246.50',
        'created': '2026-08-24T10:00:00Z',
        'kind': 'Invite',
        'status': 'Complete',
      });
      expect(dto.id, 9);
      expect(dto.amount, 20);
      expect(dto.chfValue, 246.5);
    });

    test('reads created from a Unix timestamp', () {
      final dto = ReferralPayoutDto.fromJson({
        'id': 9,
        'amount': 20,
        'chfValue': 246.5,
        'created': 1787565600,
        'status': 'Complete',
      });
      expect(dto.created, DateTime.utc(2026, 8, 24, 10));
    });

    test('stringifies a numeric txHash', () {
      final dto = ReferralPayoutDto.fromJson({
        'id': 9,
        'amount': 20,
        'chfValue': 1,
        'created': '2026-08-24T10:00:00Z',
        'status': 'Complete',
        'txHash': 123,
      });
      expect(dto.txHash, '123');
    });

    test('pending and failed payouts are not settled; missing status is', () {
      expect(
        ReferralPayoutDto.fromJson({
          'id': 1,
          'amount': 20,
          'chfValue': 1,
          'created': '2026-08-24T10:00:00Z',
          'status': 'Pending',
        }).isSettled,
        isFalse,
      );
      expect(
        ReferralPayoutDto.fromJson({
          'id': 2,
          'amount': 20,
          'chfValue': 1,
          'created': '2026-08-24T10:00:00Z',
        }).isSettled,
        isTrue,
      );
    });
  });

  group('$ReferralCreatedInviteDto.fromJson', () {
    test('parses code, url, guest name and optional copy text', () {
      final dto = ReferralCreatedInviteDto.fromJson({
        'code': 'AB12',
        'url': 'https://realunit.app/invite/AB12',
        'guestName': 'Alice',
        'copyText': 'Hey Alice',
      });

      expect(dto.code, 'AB12');
      expect(dto.url, 'https://realunit.app/invite/AB12');
      expect(dto.guestName, 'Alice');
      expect(dto.copyText, 'Hey Alice');
    });

    test('EN share text falls back to DE copyText', () {
      final dto = ReferralCreatedInviteDto.fromJson({
        'code': 'AB12',
        'url': 'https://realunit.app/invite/AB12',
        'guestName': 'Alice',
        'copyText': 'Hey Alice, Björn lädt dich ein',
        'copyTextEn': 'Hey Alice, Björn is inviting you',
      });
      expect(dto.copyTextForLocale('en'), 'Hey Alice, Björn is inviting you');
      expect(dto.copyTextForLocale('de'), 'Hey Alice, Björn lädt dich ein');
    });

    test('EN share text ignores empty copyTextEn', () {
      final dto = ReferralCreatedInviteDto.fromJson({
        'code': 'AB12',
        'url': 'https://realunit.app/invite/AB12',
        'guestName': 'Alice',
        'copyText': 'Hey Alice, Björn lädt dich ein',
        'copyTextEn': '',
      });
      expect(dto.copyTextForLocale('en'), 'Hey Alice, Björn lädt dich ein');
    });
  });

  group('$ReferralCodeLookupDto.fromJson', () {
    test('maps invite recognition and promo campaign text', () {
      final invite = ReferralCodeLookupDto.fromJson({
        'kind': 'invite',
        'inviterName': 'Björn',
        'inviteeName': 'Alice',
      });
      expect(invite.isInvite, isTrue);
      expect(invite.inviterName, 'Björn');
      expect(invite.displayInviterName, 'Björn');

      final promo = ReferralCodeLookupDto.fromJson({
        'kind': 'Promo',
        'actionText': 'DE action',
        'campaignTextEn': 'EN campaign',
      });
      expect(promo.isPromo, isTrue);
      expect(promo.campaignTextForLocale('en'), 'EN campaign');
      expect(promo.campaignTextForLocale('de'), 'DE action');
    });

    test('whitespace-only inviterName is not displayed', () {
      final invite = ReferralCodeLookupDto.fromJson({
        'kind': 'invite',
        'inviterName': '   ',
      });
      expect(invite.isInvite, isTrue);
      expect(invite.displayInviterName, isNull);
    });

    test('EN campaign text ignores empty campaignTextEn', () {
      final promo = ReferralCodeLookupDto.fromJson({
        'kind': 'promo',
        'actionText': 'DE action',
        'campaignTextEn': '   ',
      });
      expect(promo.campaignTextForLocale('en'), 'DE action');
    });

    test('EN prefers actionTextEn and promo minBuyRealu defaults to 200', () {
      final promo = ReferralCodeLookupDto.fromJson({
        'kind': 'promo',
        'actionText': 'DE action',
        'actionTextEn': 'EN action',
      });
      expect(promo.campaignTextForLocale('en'), 'EN action');
      expect(promo.minBuyRealu, 200);
      expect(
        ReferralCodeLookupDto.fromJson({'kind': 'invite'}).minBuyRealu,
        isNull,
      );
    });

    test('infers promo from action text when kind is omitted', () {
      final promo = ReferralCodeLookupDto.fromJson({
        'actionText': 'Mit dem Code EVT1 schenken wir dir 20 Token.',
      });
      expect(promo.isPromo, isTrue);
    });

    test('infers invite from inviterName when kind is omitted', () {
      final invite = ReferralCodeLookupDto.fromJson({
        'inviterName': 'Björn',
      });
      expect(invite.isInvite, isTrue);
    });

    test('blank kind is ignored so action text still infers promo', () {
      final promo = ReferralCodeLookupDto.fromJson({
        'kind': '  ',
        'actionText': 'Mit dem Code EVT1 schenken wir dir 20 Token.',
      });
      expect(promo.isPromo, isTrue);
    });

    test('inviterName wins over action text when kind is omitted', () {
      final invite = ReferralCodeLookupDto.fromJson({
        'inviterName': 'Björn',
        'actionText': 'Mit dem Code EVT1 schenken wir dir 20 Token.',
      });
      expect(invite.isInvite, isTrue);
    });
  });
}
