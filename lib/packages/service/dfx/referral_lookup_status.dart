/// Public lookup statuses that mean the code is invalid or spent.
/// Keep in sync with `mapResult` in realunit-web `public/js/lib/invite-core.js`.
/// Transport failures (5xx, 401, 408, 429) are not invalid — the code may still
/// work on retry and must not be shown as expired.
bool isReferralLookupInvalidStatus(int? status) {
  return status == 400 ||
      status == 404 ||
      status == 409 ||
      status == 410 ||
      status == 422;
}
