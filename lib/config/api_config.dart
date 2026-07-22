/// API connection settings for the SkillProof backend.
class ApiConfig {
  ApiConfig._();

  /// Defaults to the deployed production API — a plain `flutter run` with
  /// no override talks to the real backend. For local development against
  /// an API running on your own machine, override at build/run time, e.g.:
  ///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000
  ///
  /// (10.0.2.2 is the Android emulator's alias for the host machine's
  /// localhost; iOS simulator should use http://localhost:4000; a physical
  /// device needs your machine's LAN IP.)
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.skillproof.flairfuture.com',
  );

  /// Base URL of the web app — for links that only make sense in a full
  /// browser: the public badge certificate page, and assessments (their
  /// integrity monitoring is browser-based, so assessments are
  /// deliberately not part of this native app at all). Opened via
  /// url_launcher, not fetched, so unlike [baseUrl] this needs to be
  /// reachable by the device's own browser.
  ///
  /// Defaults to the deployed production web app. For local development,
  /// override at build/run time, e.g.:
  ///   flutter run --dart-define=WEB_BASE_URL=http://192.168.1.50:3000
  /// (your machine's LAN IP — a device's own browser can't resolve
  /// localhost or the 10.0.2.2 emulator-only loopback alias).
  static const String webBaseUrl = String.fromEnvironment(
    'WEB_BASE_URL',
    defaultValue: 'https://skillproof.flairfuture.com',
  );
}
