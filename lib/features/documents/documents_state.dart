import '../../models/billing_document.dart';

sealed class DocumentsState {
  const DocumentsState();
}

class DocumentsLoading extends DocumentsState {
  const DocumentsLoading();
}

class DocumentsError extends DocumentsState {
  const DocumentsError(this.message);

  final String message;
}

/// Flat fields, same idiom as ProfileLoaded — the download action has its
/// own per-row busy/error state layered on top of the loaded list, rather
/// than a nested state machine.
class DocumentsLoaded extends DocumentsState {
  const DocumentsLoaded(this.documents, {this.downloadingId, this.downloadError});

  final List<BillingDocument> documents;

  /// The document currently being resolved to a download URL, if any —
  /// used to show a per-row spinner without disabling the whole list.
  final String? downloadingId;
  final String? downloadError;

  DocumentsLoaded copyWith({
    String? downloadingId,
    bool clearDownloadingId = false,
    String? downloadError,
    bool clearDownloadError = false,
  }) {
    return DocumentsLoaded(
      documents,
      downloadingId: clearDownloadingId ? null : (downloadingId ?? this.downloadingId),
      downloadError: clearDownloadError ? null : (downloadError ?? this.downloadError),
    );
  }
}
