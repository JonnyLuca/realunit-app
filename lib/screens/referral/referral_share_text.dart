/// Share copy from the API when present; otherwise the localised template.
/// Empty `copyText` / `copyTextEn` must not hide the fallback.
String referralShareText({
  required String? fromApi,
  required String guestName,
  required String url,
  required String Function(String guestName, String hostName, String url)
  fallback,
}) {
  if (fromApi != null && fromApi.trim().isNotEmpty) return fromApi;
  return fallback(guestName, 'RealUnit', url);
}
