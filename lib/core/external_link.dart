import 'package:url_launcher/url_launcher.dart';

/// Opens [url] in an in-app browser sheet (SFSafariViewController / Custom Tab) —
/// used for pages that only make sense outside the app: the public badge
/// certificate page, and assessments (deliberately browser-only, since
/// their integrity monitoring is browser-based).
///
/// Throws if nothing on the device can handle it, so callers can show
/// their own error UI rather than this silently failing to notice.
Future<void> openInBrowser(String url) async {
  final uri = Uri.parse(url);
  // In-app browser sheet, not the external browser: the candidate stays
  // inside MyAmbii (with a Done button back), which App Store review expects
  // for core flows like assessments. Same Safari/Chrome engine underneath,
  // so browser-based integrity monitoring behaves the same.
  final launched = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  if (!launched) {
    throw Exception('Could not open $url');
  }
}
