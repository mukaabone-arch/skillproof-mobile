import 'package:url_launcher/url_launcher.dart';

/// Opens [url] in the device's default browser (not an in-app webview) —
/// used for pages that only make sense outside the app: the public badge
/// certificate page, and assessments (deliberately browser-only, since
/// their integrity monitoring is browser-based).
///
/// Throws if nothing on the device can handle it, so callers can show
/// their own error UI rather than this silently failing to notice.
Future<void> openInBrowser(String url) async {
  final uri = Uri.parse(url);
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched) {
    throw Exception('Could not open $url');
  }
}
