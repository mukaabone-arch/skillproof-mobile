import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/profile_viewers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/locked_preview.dart';
import '../profile_viewers_controller.dart';
import '../profile_viewers_state.dart';

const Map<String, String> _sourceLabel = {
  'DETAIL_VIEW': 'Viewed your profile',
  'SHORTLIST': 'Shortlisted you',
  'REJECT': 'Reviewed your application',
  'STATUS_CHANGE': 'Updated your application status',
  'MESSAGE': 'Messaged you',
};

const _maxPlaceholderRows = 4;

/// GET /profiles/me/viewers — count_only for Free, full detail for Premium.
/// The canonical locked-state example from the product spec: "N employers
/// viewed your profile" stays a real, specific number even on Free; only the
/// *who* is withheld, shown as a blurred generic preview (not fabricated
/// real-looking data — the API genuinely never sends viewer rows in
/// count_only mode, so the placeholder rows just illustrate the shape of
/// what Premium unlocks, sized to the real count). Mirrors
/// apps/web/components/ProfileViewersPanel.tsx.
class ProfileViewersSection extends ConsumerWidget {
  const ProfileViewersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileViewersControllerProvider);

    return switch (state) {
      ProfileViewersLoading() => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.space4),
          child: Center(child: CircularProgressIndicator()),
        ),
      ProfileViewersError(:final message) =>
        Text(message, style: AppTypography.bodySmall.copyWith(color: AppColors.errorBright)),
      ProfileViewersLoaded(:final result) => _Body(result: result),
    };
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.result});

  final ProfileViewersResult result;

  @override
  Widget build(BuildContext context) {
    final count = switch (result) {
      ProfileViewersCountOnly(:final count) => count,
      ProfileViewersFull(:final viewers) => viewers.length,
    };
    final teaser = count == 0
        ? 'No employers have viewed your profile yet.'
        : '$count employer${count == 1 ? ' has' : 's have'} viewed your profile.';

    return switch (result) {
      ProfileViewersCountOnly() when count == 0 => Text(teaser, style: AppTypography.bodySmall),
      ProfileViewersCountOnly() => LockedPreview(
          teaser: teaser,
          overlayLabel: 'Premium unlocks who',
          child: Column(
            children: [
              for (var i = 0; i < count.clamp(0, _maxPlaceholderRows); i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.space2),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Employer', style: AppTypography.titleSmall),
                        const SizedBox(height: AppSpacing.space1),
                        Text('Viewed your profile', style: AppTypography.bodySmall),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ProfileViewersFull(:final viewers) when viewers.isEmpty =>
        Text(teaser, style: AppTypography.bodySmall),
      ProfileViewersFull(:final viewers) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final v in viewers)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.space2),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(v.orgName ?? 'An employer', style: AppTypography.titleSmall),
                      const SizedBox(height: AppSpacing.space1),
                      Text(
                        '${_sourceLabel[v.source] ?? v.source} · ${_formatDate(v.viewedAt)}',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
    };
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
