import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// The canonical locked-state pattern: a Premium feature stays *visible but
/// withheld* rather than absent — [teaser] is always real data (e.g. a
/// genuine count), never a hardcoded marketing line, so the locked state
/// feels concrete rather than a generic paywall. [child] is a real preview
/// of the shape of what unlocks (e.g. placeholder rows sized to the real
/// count), rendered blurred and non-interactive behind an overlay label.
/// Mirrors apps/web/components/LockedPreview.tsx; the overlay here is
/// informational only, not a tappable CTA — there's no /upgrade
/// destination in this app yet (no /plans endpoint, no payment
/// integration), so it doesn't pretend to link anywhere.
class LockedPreview extends StatelessWidget {
  const LockedPreview({
    required this.teaser,
    required this.child,
    this.overlayLabel = 'Premium unlocks this',
    super.key,
  });

  final String teaser;
  final Widget child;
  final String overlayLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(teaser, style: AppTypography.bodyMedium),
        const SizedBox(height: AppSpacing.space3),
        Stack(
          children: [
            // Full-width so the Stack always has room for the overlay pill
            // below, regardless of how narrow the blurred content itself is
            // (e.g. a single short placeholder row).
            SizedBox(
              width: double.infinity,
              child: IgnorePointer(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: Opacity(opacity: 0.5, child: child),
                ),
              ),
            ),
            Positioned.fill(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4, vertical: AppSpacing.space2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.warning),
                      const SizedBox(width: AppSpacing.space2),
                      Text(overlayLabel, style: AppTypography.metaLabel(color: AppColors.warning)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
