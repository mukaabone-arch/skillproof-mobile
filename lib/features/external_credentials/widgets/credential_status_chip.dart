import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

/// Status pill for an [ExternalCredential] — deliberately never touches
/// [AppColors.success]/[AppColors.success]/[AppColors.successSoft].
/// Those are reserved exclusively for SkillProof-assessed badges
/// ([SkillBadge], the Badges screen); an external credential's VERIFIED
/// state instead gets the app's brand — the same "distinct, non-green"
/// rule the web app's `Badge variant="default"` follows for the identical
/// case. An employer (or candidate) must be able to tell the two tiers
/// apart at a glance from color alone.
class CredentialStatusChip extends StatelessWidget {
  const CredentialStatusChip({required this.verificationState, super.key});

  /// Raw PENDING | VERIFIED | FAILED.
  final String verificationState;

  @override
  Widget build(BuildContext context) {
    final (label, fg, bg) = switch (verificationState) {
      'VERIFIED' => ('Verified via Credly', AppColors.primary, AppColors.primarySoft),
      'FAILED' => ("Couldn't verify", AppColors.errorBright, AppColors.errorSoft),
      _ => ('Pending', AppColors.textTertiary, AppColors.surfaceElevated),
    };

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
