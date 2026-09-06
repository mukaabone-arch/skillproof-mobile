/// One row of GET /documents/me — a candidate's own GST tax invoices/
/// receipts for Premium subscription charges. Read-only, same "compliance
/// obligation, not an editable record" scope as apps/web/app/profile/billing.
class BillingDocument {
  BillingDocument({
    required this.id,
    required this.documentNumber,
    required this.series,
    required this.status,
    required this.totalPaise,
    required this.issuedAt,
  });

  factory BillingDocument.fromJson(Map<String, dynamic> json) => BillingDocument(
        id: json['id'] as String,
        documentNumber: json['documentNumber'] as String,
        series: json['series'] as String,
        status: json['status'] as String,
        totalPaise: json['totalPaise'] as int,
        issuedAt: DateTime.parse(json['issuedAt'] as String),
      );

  final String id;
  final String documentNumber;

  /// Raw 'TAX_INVOICE' | 'RECEIPT'.
  final String series;

  /// Raw 'PENDING' | 'GENERATED' | 'FAILED_NEEDS_ATTENTION' — only
  /// 'GENERATED' has a downloadable file; the other two show as "Preparing…"
  /// with no download action, matching apps/web/app/profile/billing exactly.
  final String status;
  final int totalPaise;
  final DateTime issuedAt;

  bool get isDownloadable => status == 'GENERATED';
  bool get isTaxInvoice => series == 'TAX_INVOICE';
}
