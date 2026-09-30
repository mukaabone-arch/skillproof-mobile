import '../config/api_config.dart';
import 'external_link.dart';

/// Fetches a short-lived, single-use exchange code from the API (POST
/// /auth/web-session, via AuthRepository.createWebSessionCode). Injected
/// rather than this file depending on AuthRepository/Riverpod directly —
/// callers supply `() => ref.read(authRepositoryProvider).createWebSessionCode()`.
typedef WebSessionCodeFactory = Future<String> Function();

/// Opens a web page that requires the candidate to be signed in, bridging
/// the app's session across via a short-lived single-use code — a browser
/// has no access to this app's flutter_secure_storage JWT, so without this
/// a signed-in candidate hits a login wall on every [openInBrowser]
/// hand-off to a page that requires auth (see /auth/handoff on the web
/// side, which redeems the code for a session).
///
/// Public pages (/badges/{verifyHash}) and external URLs must keep using
/// [openInBrowser] directly — they need no session and must work
/// signed-out.
///
/// [openBrowser] defaults to [openInBrowser]; tests inject a fake so this
/// is verifiable without a platform channel.
Future<void> openWebAuthenticated(
  String path,
  WebSessionCodeFactory createCode, {
  Future<void> Function(String url) openBrowser = openInBrowser,
}) async {
  try {
    final code = await createCode();
    final next = Uri.encodeComponent(path);
    await openBrowser('${ApiConfig.webBaseUrl}/auth/handoff?code=$code&next=$next');
  } catch (_) {
    // Degrade to today's behaviour rather than a dead button: the candidate
    // lands logged-out but can sign in manually.
    await openBrowser('${ApiConfig.webBaseUrl}$path');
  }
}
