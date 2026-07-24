import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/external_link.dart';
import '../../../models/certification.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_card.dart';
import '../certifications_repository.dart';
import 'certification_trust_chip.dart';

/// One certification row. Structurally similar to ExternalCredentialCard
/// (status indicator + title + meta + link-out) but adds an edit action —
/// certifications, unlike the old paste-a-URL credentials, are full records
/// a candidate can revise — and a "view uploaded file" action, since the
/// upload is only ever fetched through an authenticated proxy, never a
/// public URL (see Certification.fileUrl's doc comment).
class CertificationCard extends ConsumerWidget {
  const CertificationCard({
    required this.certification,
    required this.deleting,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final Certification certification;
  final bool deleting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = certification;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.space2,
                  runSpacing: AppSpacing.space2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    CertificationTrustChip(status: c.verificationStatus),
                    if (c.isExpiringSoon)
                      _ExpiringSoonPill(expiryDate: c.expiryDate!),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.textTertiary),
                    tooltip: 'Edit',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: onEdit,
                  ),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: deleting
                        ? const Padding(
                            padding: EdgeInsets.all(6),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.textTertiary),
                            tooltip: 'Remove',
                            padding: EdgeInsets.zero,
                            onPressed: onDelete,
                          ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(c.name, style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.space1),
          Text(c.issuerLabel, style: AppTypography.bodySmall),
          const SizedBox(height: AppSpacing.space1),
          Text(_datesLine(c), style: AppTypography.bodySmall),
          if (c.credentialId != null && c.credentialId!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space1),
            Text('Credential ID: ${c.credentialId}', style: AppTypography.bodySmall),
          ],
          if (c.credentialUrl != null) ...[
            const SizedBox(height: AppSpacing.space2),
            _LinkRow(label: 'View credential', onTap: () => _openUrl(context, c.credentialUrl!)),
          ],
          if (c.fileUrl != null) ...[
            const SizedBox(height: AppSpacing.space2),
            _LinkRow(label: 'View uploaded file', onTap: () => _viewFile(context, ref, c.fileUrl!)),
          ],
        ],
      ),
    );
  }

  String _datesLine(Certification c) {
    final issued = _formatDate(c.issueDate);
    final expires = c.expiryDate == null ? 'No expiration' : 'Expires ${_formatDate(c.expiryDate!)}';
    return 'Issued $issued · $expires';
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    try {
      await openInBrowser(url);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open that link. Please try again.')),
        );
      }
    }
  }

  /// The uploaded file is always an image (see Certification's doc comment
  /// on PDF being out of scope on mobile) — fetched via the authenticated
  /// proxy and shown in a full-screen dialog, rather than handed to
  /// url_launcher, since there is no public URL to open.
  Future<void> _viewFile(BuildContext context, WidgetRef ref, String path) async {
    try {
      final bytes = await ref.read(certificationsRepositoryProvider).getFile(path);
      if (bytes == null) throw Exception('File not found');
      if (context.mounted) {
        await showDialog<void>(
          context: context,
          builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(AppSpacing.space4),
            child: InteractiveViewer(child: Image.memory(bytes)),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load the uploaded file. Please try again.')),
        );
      }
    }
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppTypography.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          const Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.primary),
        ],
      ),
    );
  }
}

/// "Expires in N days" — a second, separate pill next to the main trust
/// chip (never merged into it), matching web's own two-chip layout for
/// this case. Only ever shown alongside VERIFIED/LINK_PROVIDED/
/// SELF_REPORTED — [Certification.isExpiringSoon] is false once a cert has
/// already lapsed into EXPIRED, so this and the EXPIRED chip never appear
/// together.
class _ExpiringSoonPill extends StatelessWidget {
  const _ExpiringSoonPill({required this.expiryDate});

  final DateTime expiryDate;

  @override
  Widget build(BuildContext context) {
    final days = expiryDate.difference(DateTime.now()).inHours / 24;
    final daysLeft = days < 0 ? 0 : days.ceil();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space3, vertical: AppSpacing.space1),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
      ),
      child: Text('Expires in $daysLeft days', style: AppTypography.metaLabel(color: AppColors.warning)),
    );
  }
}

String _formatDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
