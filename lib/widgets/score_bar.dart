import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Match-score readout (0-100) for the "Matched to you" tab — indigo, never
/// green. A match score isn't a verified-skill signal, so it stays in the
/// primary/progress color family per the rule on [AppColors].
class ScoreBar extends StatelessWidget {
  const ScoreBar({required this.score, this.width = 64, super.key});

  final int score;
  final double width;

  @override
  Widget build(BuildContext context) {
    final clamped = score.clamp(0, 100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$clamped', style: AppTypography.mono(size: 15, weight: FontWeight.w700, color: AppColors.indigoLight)),
        const SizedBox(height: 4),
        SizedBox(
          width: width,
          height: 6,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: clamped / 100,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.indigoLight),
            ),
          ),
        ),
      ],
    );
  }
}
