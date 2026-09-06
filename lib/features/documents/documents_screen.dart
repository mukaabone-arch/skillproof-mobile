import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/billing_document.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import 'documents_controller.dart';
import 'documents_state.dart';

String _rupees(int paise) => '₹${(paise / 100).toStringAsFixed(2)}';

String _formatDate(DateTime utc) {
  final local = utc.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}

/// A candidate's own GST tax invoices/receipts for Premium subscription
/// charges — read-only, mirrors apps/web/app/profile/billing/page.tsx
/// exactly (same fields, same "Preparing…" state for a not-yet-generated
/// document, same fresh-fetch-then-open download flow).
class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(documentsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Billing documents')),
      body: switch (state) {
        DocumentsLoading() => const Center(child: CircularProgressIndicator()),
        DocumentsError(:final message) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space5),
              child: Text(message, style: AppTypography.bodyMedium.copyWith(color: AppColors.errorBright)),
            ),
          ),
        DocumentsLoaded(:final documents) when documents.isEmpty => const EmptyState(
            message: 'No billing documents yet — these appear here after your first Premium charge.',
          ),
        DocumentsLoaded() => RefreshIndicator(
            onRefresh: () => ref.read(documentsControllerProvider.notifier).load(),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.space4),
              children: [
                Text(
                  'Tax invoices and receipts for your MyAmbii Premium subscription charges.',
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.space4),
                if (state.downloadError != null) ...[
                  Text(state.downloadError!, style: AppTypography.bodySmall.copyWith(color: AppColors.errorBright)),
                  const SizedBox(height: AppSpacing.space3),
                ],
                for (final doc in state.documents) ...[
                  _DocumentRow(document: doc, busy: state.downloadingId == doc.id),
                  const SizedBox(height: AppSpacing.space3),
                ],
              ],
            ),
          ),
      },
    );
  }
}

class _DocumentRow extends ConsumerWidget {
  const _DocumentRow({required this.document, required this.busy});

  final BillingDocument document;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(document.documentNumber, style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  '${document.isTaxInvoice ? 'Tax invoice' : 'Receipt'} · '
                  '${_formatDate(document.issuedAt)} · ${_rupees(document.totalPaise)}',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          if (document.isDownloadable)
            TextButton(
              onPressed: busy ? null : () => ref.read(documentsControllerProvider.notifier).download(document.id),
              child: busy
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Download'),
            )
          else
            Text('Preparing…', style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}
