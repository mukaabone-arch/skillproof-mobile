import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// A match at/above this score reads as "strong" (bold brand); below it,
/// "developing" (muted neutral). Mirrors MATCH_STRONG_THRESHOLD in
/// apps/web/components/Dashboard.tsx — keep the two in sync.
const int kMatchStrongThreshold = 65;

/// Match-score readout (0-100) for the "Matched to you" tab and Home's top
/// matches — brand family only, never green. A match score isn't a
/// verified-skill signal, so it stays out of [AppColors.success] per the
/// rule on [AppColors]; confidence is instead color-coded *within* that one
/// accent — a strong match gets the bold/bright brand fill and label, a
/// weaker one falls back to a muted neutral rather than reaching for a
/// second hue.
class ScoreBar extends StatelessWidget {
  const ScoreBar({required this.score, this.width = 64, this.showLabel = true, super.key});

  final int score;
  final double width;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final clamped = score.clamp(0, 100);
    final strong = clamped >= kMatchStrongThreshold;
    final fillColor = strong ? AppColors.primary : AppColors.textTertiary;
    final numeralColor = strong ? AppColors.primary : AppColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$clamped%', style: AppTypography.meta(size: 15, weight: FontWeight.w700, color: numeralColor)),
        if (showLabel) ...[
          const SizedBox(height: 2),
          Text(
            strong ? 'Strong match' : 'Developing',
            style: AppTypography.meta(size: 10, weight: FontWeight.w600, color: numeralColor),
          ),
        ],
        const SizedBox(height: 4),
        SizedBox(
          width: width,
          height: 6,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: clamped / 100,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(fillColor),
            ),
          ),
        ),
      ],
    );
  }
}
