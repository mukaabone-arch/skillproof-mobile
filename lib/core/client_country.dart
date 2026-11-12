import 'dart:io' show Platform;

/// Best guess at the user's country, sent to the API as X-Client-Country.
/// The API records it the first time it sees a candidate and uses it to
/// decide whether a verified phone is required: our SMS codes only reach
/// Indian numbers, so outside India a verified email is enough.
///
/// India is decided by the device clock (UTC+05:30), because many phones in
/// India use an en_US locale. Elsewhere the locale's region is used
/// ("en_AE" → "AE"), and "ZZ" means "not India, country unknown".
String clientCountry({Duration? utcOffset, String? localeName}) {
  final offset = utcOffset ?? DateTime.now().timeZoneOffset;
  if (offset == const Duration(hours: 5, minutes: 30)) return 'IN';
  String locale;
  try {
    locale = localeName ?? Platform.localeName;
  } catch (_) {
    locale = '';
  }
  final match = RegExp(r'^[a-zA-Z]{2,3}[-_]([A-Za-z]{2})\b').firstMatch(locale);
  return match?.group(1)?.toUpperCase() ?? 'ZZ';
}
