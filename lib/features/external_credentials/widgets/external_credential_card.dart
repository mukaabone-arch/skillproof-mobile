import 'package:flutter/material.dart';

import '../../../core/external_link.dart';
import '../../../models/external_credential.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_card.dart';
import 'credential_status_chip.dart';

/// One external credential row. Structurally similar to BadgeCard (status
/// indicator + title + meta + link-out) but never reaches for
/// success-green — see [CredentialStatusChip]'s doc for why. VERIFIED
/// credentials link out to the Credly badge itself (not an in-app page —
/// there is nothing to render here beyond what Credly already shows);
/// FAILED/PENDING show the pasted URL instead so the candidate can
/// double-check what they submitted.
class ExternalCredentialCard extends StatelessWidget {
  const ExternalCredentialCard({
    required this.credential,
    required this.deleting,
    required this.onDelete,
    super.key,
  });

  final ExternalCredential credential;
  final bool deleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CredentialStatusChip(verificationState: credential.verificationState),
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
          const SizedBox(height: AppSpacing.space2),
          if (credential.isVerified)
            _VerifiedBody(credential: credential)
          else
            _UnverifiedBody(credential: credential),
        ],
      ),
    );
  }
}

class _VerifiedBody extends StatelessWidget {
  const _VerifiedBody({required this.credential});

  final ExternalCredential credential;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(credential.name ?? 'Credential', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.space1),
        Text(credential.issuerLabel, style: AppTypography.bodySmall),
        const SizedBox(height: AppSpacing.space1),
        Text(_datesLine(credential), style: AppTypography.bodySmall),
        const SizedBox(height: AppSpacing.space2),
        InkWell(
          onTap: () => _openBadge(context, credential.credentialUrl),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'View badge on Credly',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.primary),
            ],
          ),
        ),
      ],
    );
  }

  String _datesLine(ExternalCredential credential) {
    final issued = credential.issuedAt == null ? 'Unknown' : _formatDate(credential.issuedAt!);
    final expires =
        credential.expiresAt == null ? 'No expiration' : 'Expires ${_formatDate(credential.expiresAt!)}';
    return 'Issued $issued · $expires';
  }

  Future<void> _openBadge(BuildContext context, String url) async {
    try {
      await openInBrowser(url);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the badge link. Please try again.')),
        );
      }
    }
  }
}

class _UnverifiedBody extends StatelessWidget {
  const _UnverifiedBody({required this.credential});

  final ExternalCredential credential;

  @override
  Widget build(BuildContext context) {
    final message = credential.isFailed
        ? "Couldn't verify this badge — make sure it's set to public on Credly, then remove this and paste the URL again."
        : "We don't automatically verify this issuer yet — this link is saved but unconfirmed.";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: AppTypography.bodySmall),
        const SizedBox(height: AppSpacing.space1),
        Text(
          credential.credentialUrl,
          style: AppTypography.bodySmall,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

String _formatDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
