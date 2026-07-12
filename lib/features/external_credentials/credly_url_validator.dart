/// Mirrors apps/web/app/profile/page.tsx's CREDLY_BADGE_URL_RE /
/// CREDLY_PROFILE_URL_RE / validateCredentialUrl exactly, and (loosely) the
/// backend's CredlyVerificationService badge-URL pattern — kept client-side
/// so we reject a non-badge URL before ever hitting the API, instead of
/// creating a doomed PENDING record for a link we already know can't verify.
final RegExp _credlyBadgeUrlRe =
    RegExp(r'^https?://(?:www\.)?credly\.com/badges/[0-9a-fA-F-]{36}(?:[/?#].*)?$');
final RegExp _credlyProfileUrlRe = RegExp(r'^https?://(?:www\.)?credly\.com/users/', caseSensitive: false);

/// Returns null when [url] is a valid Credly badge URL (or empty — an
/// empty field isn't itself invalid, just incomplete). Otherwise returns a
/// user-facing message explaining why, so the caller can show it inline
/// and refuse to submit.
String? validateCredlyBadgeUrl(String url) {
  if (url.isEmpty) return null;
  if (_credlyBadgeUrlRe.hasMatch(url)) return null;
  if (_credlyProfileUrlRe.hasMatch(url)) {
    return "That's a profile URL — open a specific badge and paste its URL instead.";
  }
  return 'Paste the URL of a single Credly badge — it should look like credly.com/badges/<id>.';
}
