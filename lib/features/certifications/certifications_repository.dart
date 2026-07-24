import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';

import '../../core/api_client.dart';
import '../../core/providers.dart';
import '../../models/certification.dart';

final certificationsRepositoryProvider = Provider<CertificationsRepository>((ref) {
  return CertificationsRepository(apiClient: ref.read(apiClientProvider));
});

/// Talks to /profiles/me/certifications. Field names below must match
/// CertificationFieldsDto on the API exactly — create and update share the
/// same shape (the API always expects the whole record, not a partial
/// patch, since the edit form always resubmits every field — see
/// apps/api/src/modules/certifications/certifications.dto.ts's own doc
/// comment on this). Both are multipart/form-data (an optional file
/// alongside the text fields), which is why they go through
/// [ApiClient.multipart] rather than [ApiClient.post]/[ApiClient.patch].
class CertificationsRepository {
  CertificationsRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<List<Certification>> list() async {
    final response = await apiClient.get('/profiles/me/certifications') as List<dynamic>;
    return response.cast<Map<String, dynamic>>().map(Certification.fromJson).toList();
  }

  Future<Certification> create({
    required String name,
    required String issuer,
    String? issuerOther,
    required DateTime issueDate,
    DateTime? expiryDate,
    String? credentialId,
    String? credentialUrl,
    File? file,
  }) async {
    final response = await apiClient.multipart(
      'POST',
      '/profiles/me/certifications',
      fields: _fields(
        name: name,
        issuer: issuer,
        issuerOther: issuerOther,
        issueDate: issueDate,
        expiryDate: expiryDate,
        credentialId: credentialId,
        credentialUrl: credentialUrl,
      ),
      file: file,
      fileField: 'file',
      fileContentType: file == null ? null : _mediaTypeForImage(file.path),
    ) as Map<String, dynamic>;
    return Certification.fromJson(response);
  }

  /// [file] is only sent if the candidate picked a new one in this edit —
  /// omitting it (rather than resending the old one) is what tells the API
  /// to keep whatever file is already on record, same "untouched file input
  /// means keep the original" contract the web edit form uses.
  Future<Certification> update(
    String id, {
    required String name,
    required String issuer,
    String? issuerOther,
    required DateTime issueDate,
    DateTime? expiryDate,
    String? credentialId,
    String? credentialUrl,
    File? file,
  }) async {
    final response = await apiClient.multipart(
      'PATCH',
      '/profiles/me/certifications/$id',
      fields: _fields(
        name: name,
        issuer: issuer,
        issuerOther: issuerOther,
        issueDate: issueDate,
        expiryDate: expiryDate,
        credentialId: credentialId,
        credentialUrl: credentialUrl,
      ),
      file: file,
      fileField: 'file',
      fileContentType: file == null ? null : _mediaTypeForImage(file.path),
    ) as Map<String, dynamic>;
    return Certification.fromJson(response);
  }

  Future<void> remove(String id) async {
    await apiClient.delete('/profiles/me/certifications/$id');
  }

  /// Fetches an uploaded certification file's bytes through the
  /// authenticated proxy — [path] is [Certification.fileUrl] itself
  /// (already the full `/profiles/me/certifications/:id/file` path), same
  /// pattern as ProfileRepository.getPhoto.
  Future<Uint8List?> getFile(String path) => apiClient.getBytes(path);

  Map<String, String> _fields({
    required String name,
    required String issuer,
    String? issuerOther,
    required DateTime issueDate,
    DateTime? expiryDate,
    String? credentialId,
    String? credentialUrl,
  }) {
    return {
      'name': name,
      'issuer': issuer,
      if (issuer == 'OTHER' && (issuerOther?.isNotEmpty ?? false)) 'issuerOther': issuerOther!,
      'issueDate': _isoDate(issueDate),
      if (expiryDate != null) 'expiryDate': _isoDate(expiryDate),
      if (credentialId != null && credentialId.isNotEmpty) 'credentialId': credentialId,
      if (credentialUrl != null && credentialUrl.isNotEmpty) 'credentialUrl': credentialUrl,
    };
  }

  String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// image_picker doesn't expose a mimetype directly, only a file path —
  /// same inference-by-extension approach as ProfileRepository's photo
  /// upload. Only PNG/JPG are ever picked (see CertificationForm), matching
  /// the API's fileFilter subset that's reachable without file_picker (PDF
  /// is out of scope on mobile — see Certification's own doc comment).
  MediaType _mediaTypeForImage(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return MediaType('image', 'png');
      case 'jpg':
      case 'jpeg':
      default:
        return MediaType('image', 'jpeg');
    }
  }
}
