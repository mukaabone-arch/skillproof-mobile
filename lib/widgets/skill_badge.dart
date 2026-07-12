import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// A *verified* skill chip — verified-green, and ONLY verified-green.
/// This must never be reused for a plain "required skill" chip (job
/// requirements aren't verified candidate skills); those should use a
/// neutral/indigo outline instead. See the class doc on [AppColors] for
/// why: green is reserved exclusively for verified skills, badges, and
/// certificates everywhere in this app, mirroring the web app's own rule.
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
        color: AppColors.verifiedSoft,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.verified),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_rounded, size: 13, color: AppColors.verifiedBright),
          const SizedBox(width: 5),
          Text(text, style: AppTypography.monoLabel(color: AppColors.verifiedBright)),
        ],
      ),
    );
  }
}
