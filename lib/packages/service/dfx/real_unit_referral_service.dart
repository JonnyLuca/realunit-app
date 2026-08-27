import 'dart:async';
import 'dart:convert';

import 'package:realunit_wallet/packages/config/api_config.dart';
import 'package:realunit_wallet/packages/io/normalize_referral_code.dart';
import 'package:realunit_wallet/packages/service/dfx/dfx_auth_service.dart';
import 'package:realunit_wallet/packages/service/dfx/exceptions/api_exception.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_bind_result_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_code_lookup_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_created_invite_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_invite_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_payout_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_summary_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/dto/referral_terms_dto.dart';
import 'package:realunit_wallet/packages/service/dfx/models/referral/referral_json_list.dart';

class RealUnitReferralService extends DFXAuthService {
  RealUnitReferralService(super.appStore, super.walletService);

  static const _basePath = '/v1/realunit/referral';

  /// Public lookup and the landing page abort after 15s; authenticated
  /// referral calls use the same budget so terms/summary/bind cannot hang
  /// the UI past the bundled TB fallback.
  static const lookupTimeout = Duration(seconds: 15);

  Future<T> _timed<T>(
    Future<T> future, {
    Duration timeout = lookupTimeout,
  }) => future.timeout(timeout);

  Future<ReferralTermsDto> getTerms({
    Duration timeout = lookupTimeout,
  }) async {
    final uri = buildUri(host, '$_basePath/terms');
    final response = await _timed(
      authenticatedGet(
        uri,
        headers: {'Content-Type': 'application/json'},
      ),
      timeout: timeout,
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
    final response = await _timed(
      authenticatedPost(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'accepted': true}),
      ),
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
    final response = await _timed(
      authenticatedGet(
        uri,
        headers: {'Content-Type': 'application/json'},
      ),
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
    final response = await _timed(
      authenticatedPost(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'guestName': guestName,
          'termsAccepted': true,
        }),
      ),
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
    final response = await _timed(
      authenticatedGet(
        uri,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    if (response.statusCode != 200) {
      throw ApiException.fromBody(
        response.body,
        httpStatusCode: response.statusCode,
      );
    }

    return referralJsonList(jsonDecode(response.body))
        .map(ReferralInviteDto.fromJson)
        .toList();
  }

  Future<ReferralCodeLookupDto> lookupCode(
    String code, {
    Duration timeout = lookupTimeout,
  }) async {
    final normalized = _requireCode(code);
    final template = buildUri(host, _basePath);
    final uri = template.replace(
      pathSegments: [
        ...template.pathSegments.where((s) => s.isNotEmpty),
        'code',
        normalized,
      ],
    );
    final response = await _timed(
      appStore.httpClient.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ),
      timeout: timeout,
    );

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
    final normalized = _requireCode(code);
    final uri = buildUri(host, '$_basePath/bind');
    final response = await _timed(
      authenticatedPost(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'code': normalized}),
      ),
      timeout: timeout,
    );

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
    final response = await _timed(
      authenticatedGet(
        uri,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    if (response.statusCode != 200) {
      throw ApiException.fromBody(
        response.body,
        httpStatusCode: response.statusCode,
      );
    }

    return referralJsonList(jsonDecode(response.body))
        .map(ReferralPayoutDto.fromJson)
        .toList();
  }

  String _requireCode(String code) {
    final normalized = normalizeReferralCode(code);
    if (normalized == null) {
      throw const ApiException(
        statusCode: 400,
        code: 'INVALID',
        message: 'empty',
      );
    }
    return normalized;
  }
}
