import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/score_bar.dart';
import '../../jobs/job_detail_screen.dart';
import '../../jobs/jobs_state.dart';
import '../../jobs/matched_controller.dart';
import '../../jobs/widgets/job_card.dart';

/// Top 2-3 matched jobs, inline. Matching only ever runs against verified
/// SkillProof SkillClaims (never external credentials — those don't feed
/// scoring, same rule as the backend), so the empty-state copy here talks
/// about earning a badge specifically, not "add a credential" — that
/// wouldn't actually change anything shown on this section.
class TopMatchesSection extends ConsumerWidget {
  const TopMatchesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(matchedControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Top matches', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.space3),
        _body(context, ref, state),
      ],
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, MatchedState state) {
    if (state is MatchedLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.space4),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state is MatchedError) {
      return _SectionError(
        message: state.message,
        onRetry: () => ref.read(matchedControllerProvider.notifier).load(),
      );
    }

    final jobs = (state as MatchedLoaded).jobs;
    // The API returns an empty list specifically when the candidate has no
    // verified skill claim yet (see JobsRepository.matched) — not "no jobs
    // available" — so this gets its own explanation, same wording as the
    // Jobs tab's own Matched empty state.
    if (jobs.isEmpty) {
      return const EmptyState(
        message: 'Job matches are based on your verified SkillProof skills. '
            'Earn a badge to see roles that match you.',
      );
    }

    return Column(
      children: [
        for (final matchedJob in jobs.take(3))
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space3),
            child: JobCard(
              job: matchedJob.job,
              trailing: ScoreBar(score: matchedJob.score),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => JobDetailScreen(jobId: matchedJob.job.id)),
              ),
              // Surfaces the single most relevant gap directly to the
              // candidate — this data already existed server-side (missing
              // skills) but used to be shown only to employers reviewing
              // applicants. Just the first entry, not the whole list: one
              // concrete "what would move this needle" beats an exhaustive
              // requirements dump on a compact card.
              child: matchedJob.missing.isEmpty
                  ? null
                  : Text(
                      'Add: ${matchedJob.missing.first.skillName}',
                      style: AppTypography.mono(size: 12, weight: FontWeight.w400, color: AppColors.textTertiary),
                    ),
            ),
          ),
      ],
    );
  }
}

class _SectionError extends StatelessWidget {
  const _SectionError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Text(message, style: AppTypography.bodySmall.copyWith(color: AppColors.errorBright)),
          ),
          const SizedBox(width: AppSpacing.space2),
          AppButton(label: 'Retry', variant: AppButtonVariant.secondary, onPressed: onRetry),
        ],
      ),
    );
  }
}
