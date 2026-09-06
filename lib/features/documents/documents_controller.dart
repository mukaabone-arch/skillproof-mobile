import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/external_link.dart';
import 'documents_repository.dart';
import 'documents_state.dart';

final documentsControllerProvider =
    StateNotifierProvider.autoDispose<DocumentsController, DocumentsState>((ref) {
  return DocumentsController(ref.read(documentsRepositoryProvider))..load();
});

class DocumentsController extends StateNotifier<DocumentsState> {
  DocumentsController(this._repository, {Future<void> Function(String url)? launcher})
      : _launch = launcher ?? openInBrowser,
        super(const DocumentsLoading());

  final DocumentsRepository _repository;
  final Future<void> Function(String url) _launch;

  Future<void> load() async {
    state = const DocumentsLoading();
    try {
      state = DocumentsLoaded(await _repository.list());
    } catch (e) {
      state = DocumentsError(e is ApiException ? e.message : e.toString());
    }
  }

  /// Fetches a fresh presigned URL and opens it immediately — never stores
  /// or reuses one across taps, so there's nothing to go stale (see
  /// DocumentsRepository.getDownloadUrl's own doc comment).
  Future<void> download(String documentId) async {
    final current = state;
    if (current is! DocumentsLoaded || current.downloadingId != null) return;
    state = current.copyWith(downloadingId: documentId, clearDownloadError: true);
    try {
      final url = await _repository.getDownloadUrl(documentId);
      await _launch(url);
      final latest = state;
      if (latest is DocumentsLoaded) state = latest.copyWith(clearDownloadingId: true);
    } catch (e) {
      final latest = state;
      if (latest is DocumentsLoaded) {
        state = latest.copyWith(
          clearDownloadingId: true,
          downloadError: e is ApiException ? e.message : 'Could not open this document. Please try again.',
        );
      }
    }
  }
}
