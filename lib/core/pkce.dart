import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// PKCE (RFC 7636) helpers for OAuth flows this app can't hold a client
/// secret in — currently GitHub sign-in (see AuthRepository.signInWithGithub).
/// Google's flow doesn't need this: its server auth code comes through Play
/// Services' own secure channel, not a manual browser redirect.
class Pkce {
  Pkce._();

  /// A cryptographically random code_verifier, base64url-encoded (no
  /// padding) from 32 random bytes — 43 characters, within RFC 7636's
  /// required 43-128 length and drawn entirely from its unreserved
  /// character set (base64url's alphabet is a subset of it).
  static String generateVerifier() {
    final bytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  /// S256 code_challenge for [verifier] — SHA-256 of its ASCII bytes,
  /// base64url-encoded (no padding). Never send the plain method: GitHub's
  /// authorize endpoint explicitly rejects it ("the plain code challenge
  /// method is not supported").
  static String challengeFor(String verifier) {
    final digest = sha256.convert(ascii.encode(verifier));
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  /// A random, unguessable `state` value — CSRF protection between the
  /// authorize redirect this app sends the browser to and the callback it
  /// gets back. Same shape as [generateVerifier] (doesn't need to be
  /// PKCE-shaped, just unpredictable) but kept as a separate name since it's
  /// a conceptually different value.
  static String generateState() => generateVerifier();
}
