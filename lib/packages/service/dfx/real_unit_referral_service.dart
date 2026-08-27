import 'dart:async';
import 'dart:convert';

import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_auth_service.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_bind_result_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_code_lookup_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_created_invite_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_invite_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_payout_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_summary_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_terms_dto.dart';

class RealUnitReferralService extends DFXAuthService {
  RealUnitReferralService(super.appStore, super.walletService);

  static const _basePath = '/v1/realunit/referral';

  Future<ReferralTermsDto> getTerms() async {
    final uri = buildUri(host, '$_basePath/terms');
    final response = await authenticatedGet(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw ApiException.fromBody(
        response.body,
        httpStatusCode: response.statusCode,
      );
    }

    return ReferralTermsDto.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> acceptTerms() async {
    final uri = buildUri(host, '$_basePath/terms/accept');
    final response = await authenticatedPost(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'accepted': true}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException.fromBody(
        response.body,
        httpStatusCode: response.statusCode,
      );
    }
  }

  Future<ReferralSummaryDto> getSummary() async {
    final uri = buildUri(host, '$_basePath/summary');
    final response = await authenticatedGet(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw ApiException.fromBody(
        response.body,
        httpStatusCode: response.statusCode,
      );
    }

    return ReferralSummaryDto.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<ReferralCreatedInviteDto> createInvite({
    required String guestName,
  }) async {
    final uri = buildUri(host, '$_basePath/invites');
    final response = await authenticatedPost(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'guestName': guestName,
        'termsAccepted': true,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException.fromBody(
        response.body,
        httpStatusCode: response.statusCode,
      );
    }

    return ReferralCreatedInviteDto.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<ReferralInviteDto>> getInvites() async {
    final uri = buildUri(host, '$_basePath/invites');
    final response = await authenticatedGet(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw ApiException.fromBody(
        response.body,
        httpStatusCode: response.statusCode,
      );
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => ReferralInviteDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Public code lookup used by registration preview. No Bearer token —
  /// the same route the website hits. 15s matches the landing-page abort.
  static const lookupTimeout = Duration(seconds: 15);

  Future<ReferralCodeLookupDto> lookupCode(
    String code, {
    Duration timeout = lookupTimeout,
  }) async {
    final uri = buildUri(host, '$_basePath/code/$code');
    final response = await appStore.httpClient
        .get(
          uri,
          headers: {'Content-Type': 'application/json'},
        )
        .timeout(timeout);

    if (response.statusCode != 200) {
      throw ApiException.fromBody(
        response.body,
        httpStatusCode: response.statusCode,
      );
    }

    return ReferralCodeLookupDto.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<ReferralBindResultDto> bind({
    required String code,
    Duration timeout = lookupTimeout,
  }) async {
    final uri = buildUri(host, '$_basePath/bind');
    final response = await authenticatedPost(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'code': code}),
    ).timeout(timeout);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException.fromBody(
        response.body,
        httpStatusCode: response.statusCode,
      );
    }

    return ReferralBindResultDto.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<ReferralPayoutDto>> getPayouts() async {
    final uri = buildUri(host, '$_basePath/payouts');
    final response = await authenticatedGet(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw ApiException.fromBody(
        response.body,
        httpStatusCode: response.statusCode,
      );
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => ReferralPayoutDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
