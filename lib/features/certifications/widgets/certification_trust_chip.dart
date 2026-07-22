import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

/// Trust-tier pill for a [Certification] — four visually distinct
/// treatments, strongest to weakest, matching
/// apps/web/components/CertificationsPanel.tsx's trustTierBadge exactly:
///   VERIFIED       — filled indigo, same tier [CredentialStatusChip]'s own
///                     VERIFIED state used (a live-verified Credly badge).
///   LINK_PROVIDED  — a plain, low-emphasis pill (an unverified link).
///   SELF_REPORTED  — outline only, no fill — deliberately the weakest,
///                     least confident treatment in the app. A
///                     self-uploaded PMP must never be mistaken for a
///                     verified badge; this is the whole point of the tier.
///   EXPIRED        — warning amber, overriding whichever of the three
///                     tiers above the cert started in.
/// Never reaches for [AppColors.success] — that green stays exclusively
/// SkillProof-assessed badges' color, same rule [CredentialStatusChip]
/// followed for the feature this replaces.
class CertificationTrustChip extends StatelessWidget {
  const CertificationTrustChip({required this.status, super.key});

  /// Raw VERIFIED | LINK_PROVIDED | SELF_REPORTED | EXPIRED.
  final String status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case 'EXPIRED':
        return _Pill(label: 'Expired', fg: AppColors.warning, bg: AppColors.warningSoft);
      case 'VERIFIED':
        return _Pill(label: 'Verified via Credly', fg: AppColors.primary, bg: AppColors.primarySoft);
      case 'LINK_PROVIDED':
        return _Pill(
          label: 'Link provided — unverified',
          fg: AppColors.textTertiary,
          bg: AppColors.surfaceElevated,
        );
      case 'SELF_REPORTED':
      default:
        return const _OutlinePill(label: 'Candidate-provided');
    }
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.fg, required this.bg});

  final String label;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space3, vertical: AppSpacing.space1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: fg.withValues(alpha: 0.5)),
      ),
      child: Text(label, style: AppTypography.metaLabel(color: fg)),
    );
  }
}

/// SELF_REPORTED's dedicated no-fill treatment — mirrors web's borderless,
/// unfilled span for the same tier exactly (see CertificationsPanel.tsx's
/// trustTierBadge doc comment).
class _OutlinePill extends StatelessWidget {
  const _OutlinePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space3, vertical: AppSpacing.space1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.5)),
      ),
      child: Text(label, style: AppTypography.metaLabel(color: AppColors.textSecondary)),
    );
  }
}
