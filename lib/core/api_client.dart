import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/api_config.dart';
import 'limit_reached.dart';
import 'token_storage.dart';

class ApiException implements Exception {
  ApiException(this.message, this.statusCode, [this.body]);

  final String message;
  final int statusCode;

  /// Raw decoded error body, when the response was JSON. Nest exceptions
  /// like `BadRequestException({ code: '...', message: '...' })` put a
  /// machine-readable `code` here so callers can react to specific failure
  /// reasons instead of pattern-matching on [message].
  final dynamic body;

  @override
  String toString() => message;
}

/// REST client mirroring apps/web/lib/api.ts:
/// - attaches the stored access token as a Bearer header
/// - on a 401, attempts a single token refresh (rotating both tokens)
///   and retries the original request once
/// - if the refresh itself fails, clears the stored session and notifies
///   [onSessionExpired] so the UI can route back to the login screen
class ApiClient {
  ApiClient({http.Client? httpClient, TokenStorage? tokenStorage})
      : _http = httpClient ?? http.Client(),
        _tokens = tokenStorage ?? TokenStorage();

  final http.Client _http;
  final TokenStorage _tokens;

  /// Wired up by the auth controller; called when a refresh attempt is
  /// rejected by the server (expired/revoked refresh token).
  void Function()? onSessionExpired;

  Future<dynamic> get(String path) => _send('GET', path);

  Future<dynamic> post(String path, [Map<String, dynamic>? body]) =>
      _send('POST', path, body);

  Future<dynamic> patch(String path, [Map<String, dynamic>? body]) =>
      _send('PATCH', path, body);

  Future<dynamic> delete(String path) => _send('DELETE', path);

  /// Multipart file upload (used for the profile photo; the resume path
  /// this was originally written for is still commented out below it —
  /// see profile_repository.dart) — separate from [_send] since a
  /// multipart body can't be built by the same jsonEncode-a-Map path, but
  /// shares the same 401→refresh→retry contract. [file] is re-read from
  /// disk on a retry, not just replayed from a consumed stream, since a
  /// fresh [http.MultipartFile] has to be built per attempt anyway.
  Future<dynamic> postMultipart(
    String path, {
    required File file,
    required String fieldName,
    MediaType? contentType,
  }) async {
    var response = await _rawMultipartRequest(path, file: file, fieldName: fieldName, contentType: contentType);
    if (response.statusCode == 401 && await _tryRefresh()) {
      response = await _rawMultipartRequest(path, file: file, fieldName: fieldName, contentType: contentType);
    }
    return _decode(response);
  }

  /// Fetches raw bytes from an authenticated endpoint whose response isn't
  /// JSON (the profile photo proxy) — same auth/refresh contract as
  /// [_send], but skips [_decode] since there's no JSON body to parse.
  /// Returns null on a 404 (no photo set) rather than throwing, since
  /// that's an expected, common outcome here, not a request failure.
  Future<Uint8List?> getBytes(String path) async {
    var response = await _rawRequest('GET', path, null);
    if (response.statusCode == 401 && await _tryRefresh()) {
      response = await _rawRequest('GET', path, null);
    }
    if (response.statusCode == 404) return null;
    if (response.statusCode >= 400) {
      throw ApiException('Request failed (${response.statusCode})', response.statusCode);
    }
    return response.bodyBytes;
  }

  void close() => _http.close();

  Future<dynamic> _send(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    var response = await _rawRequest(method, path, body);

    if (response.statusCode == 401 && await _tryRefresh()) {
      response = await _rawRequest(method, path, body);
    }

    return _decode(response);
  }

  Future<http.Response> _rawRequest(
    String method,
    String path,
    Map<String, dynamic>? body,
  ) async {
    final token = await _tokens.readAccessToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    switch (method) {
      case 'GET':
        return _http.get(uri, headers: headers);
      case 'POST':
        return _http.post(uri, headers: headers, body: jsonEncode(body ?? {}));
      case 'PATCH':
        return _http.patch(uri, headers: headers, body: jsonEncode(body ?? {}));
      case 'DELETE':
        return _http.delete(uri, headers: headers);
      default:
        throw UnimplementedError('Unsupported method: $method');
    }
  }

  Future<http.Response> _rawMultipartRequest(
    String path, {
    required File file,
    required String fieldName,
    MediaType? contentType,
  }) async {
    final token = await _tokens.readAccessToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final request = http.MultipartRequest('POST', uri);
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      await http.MultipartFile.fromPath(fieldName, file.path, contentType: contentType),
    );
    final streamedResponse = await _http.send(request);
    return http.Response.fromStream(streamedResponse);
  }

  Future<bool> _tryRefresh() async {
    final refreshToken = await _tokens.readRefreshToken();
    if (refreshToken == null) return false;

    try {
      final response = await _http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode >= 400) {
        // Refresh token expired or revoked server-side: the session is
        // over, not just this one request.
        await _tokens.clear();
        onSessionExpired?.call();
        return false;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      // /auth/refresh rotates the refresh token too, so both must be
      // overwritten, not just the access token.
      await _tokens.saveTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
      return true;
    } catch (_) {
      // Network error: leave the session intact and let the original
      // 401 surface as a request failure.
      return false;
    }
  }

  dynamic _decode(http.Response response) {
    final decoded =
        response.body.isEmpty ? const <String, dynamic>{} : jsonDecode(response.body);
    if (response.statusCode >= 400) {
      final message = decoded is Map && decoded['message'] != null
          ? decoded['message'].toString()
          : 'Request failed (${response.statusCode})';
      // Central 402 handling (per apps/api's entitlements README): every
      // call site throws through this one path, so nothing has to
      // special-case { code: 'LIMIT_REACHED' } itself — it just publishes
      // to LimitReachedBus, which LimitReachedListener (mounted once,
      // wrapping RootScreen) is the sole subscriber of.
      if (response.statusCode == 402 && decoded is Map && decoded['code'] == 'LIMIT_REACHED') {
        LimitReachedBus.instance.emit(LimitReachedPayload(
          metric: decoded['metric'] as String,
          limit: decoded['limit'] as int?,
          resetsAt: decoded['resetsAt'] == null ? null : DateTime.parse(decoded['resetsAt'] as String),
        ));
      }
      throw ApiException(message, response.statusCode, decoded);
    }
    return decoded;
  }
}
