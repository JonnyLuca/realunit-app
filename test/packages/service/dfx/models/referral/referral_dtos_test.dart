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

    test('EN falls back to DE when campaignTextEn is absent', () {
      final dto = ReferralBindResultDto.fromJson({
        'kind': 'Invite',
        'campaignText': 'DE only',
      });

      expect(dto.isInvite, isTrue);
      expect(dto.campaignTextForLocale('en'), 'DE only');
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

      final promo = ReferralCodeLookupDto.fromJson({
        'kind': 'Promo',
        'actionText': 'DE action',
        'campaignTextEn': 'EN campaign',
      });
      expect(promo.isPromo, isTrue);
      expect(promo.campaignTextForLocale('en'), 'EN campaign');
      expect(promo.campaignTextForLocale('de'), 'DE action');
    });
  });
}
