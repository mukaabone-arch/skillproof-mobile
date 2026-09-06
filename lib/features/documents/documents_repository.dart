import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/providers.dart';
import '../../models/billing_document.dart';

final documentsRepositoryProvider = Provider<DocumentsRepository>((ref) {
  return DocumentsRepository(apiClient: ref.read(apiClientProvider));
});

/// Talks to GET /documents/me — a candidate's own GST tax invoices/receipts
/// for Premium subscription charges. Read-only, same ownership-scoped
/// contract as apps/web/app/profile/billing.
class DocumentsRepository {
  DocumentsRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<List<BillingDocument>> list() async {
    final response = await apiClient.get('/documents/me') as List<dynamic>;
    return response.map((d) => BillingDocument.fromJson(d as Map<String, dynamic>)).toList();
  }

  /// Returns a short-lived, presigned S3 URL — never cache or reuse this
  /// across taps. Call this fresh immediately before opening it (see
  /// DocumentsController.download); the API's own web client (apps/web/app/
  /// profile/billing/page.tsx) has no special expiry handling either,
  /// because it's used the same way — fetched and opened in the same breath.
  Future<String> getDownloadUrl(String documentId) async {
    final response = await apiClient.get('/documents/me/$documentId/download') as Map<String, dynamic>;
    return response['url'] as String;
  }
}
