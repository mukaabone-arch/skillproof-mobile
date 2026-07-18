import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// A *verified* skill chip — success-green, and ONLY success-green.
/// This must never be reused for a plain "required skill" chip (job
/// requirements aren't verified candidate skills); those should use a
/// neutral/brand outline instead. See the class doc on [AppColors] for
/// why: coral is rationed to the Badges-screen earned-badge treatment
/// only, so a "verified" signal anywhere else in the app (like this one)
/// reaches for the semantic success token instead.
class SkillBadge extends StatelessWidget {
  const SkillBadge({required this.label, this.level, super.key});

  final String label;
  final String? level;

  @override
  Widget build(BuildContext context) {
    final text = level == null ? label : '$label · $level';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space3, vertical: AppSpacing.space1),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.success),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_rounded, size: 13, color: AppColors.success),
          const SizedBox(width: 5),
          Text(text, style: AppTypography.monoLabel(color: AppColors.success)),
        ],
      ),
    );
  }
}
