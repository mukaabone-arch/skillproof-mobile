import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/job.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_card.dart';
import '../../jobs/job_detail_screen.dart';
import '../../jobs/jobs_repository.dart';
import '../../jobs/jobs_state.dart';
import '../../jobs/matched_controller.dart';
import '../../root/root_tab_provider.dart';

/// Fallback for candidates with no verified skill yet: GET /jobs/matched is
/// empty for them by design (see JobsRepository.matched), so show a few
/// live roles and the first skill each one needs instead of nothing.
/// Best-effort — a failure just hides the section.
final homeJobsPreviewProvider = FutureProvider.autoDispose<List<Job>>((ref) async {
  final page = await ref.read(jobsRepositoryProvider).browse(limit: 3);
  return page.jobs;
});

class _Row {
  const _Row(this.jobId, this.title, this.org, this.chip);
  final String jobId;
  final String title;
  final String org;
  final String? chip;
}

/// "Jobs you're close to": top 3 unapplied matches with the skill each is
/// still missing (or the match %), else the browse fallback above.
class JobsCloseTo extends ConsumerWidget {
  const JobsCloseTo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matched = ref.watch(matchedControllerProvider);
    if (matched is! MatchedLoaded) return const SizedBox.shrink();

    List<_Row> rows;
    var heading = "Jobs you're close to";
    if (matched.jobs.isNotEmpty) {
      final sorted = [...matched.jobs]..sort((a, b) => b.score.compareTo(a.score));
      rows = [
        for (final m in sorted.where((m) => !m.job.alreadyApplied).take(3))
          _Row(
            m.job.id,
            m.job.title,
            m.job.orgName,
            m.missing.isNotEmpty ? 'Needs: ${m.missing.first.skillName}' : '${m.score}% match',
          ),
      ];
    } else {
      final preview = ref.watch(homeJobsPreviewProvider);
      final jobs = preview.valueOrNull ?? const <Job>[];
      heading = 'Jobs hiring now';
      rows = [
        for (final j in jobs)
          _Row(j.id, j.title, j.orgName, () {
            final req = j.requiredSkills.where((s) => s.isRequired).toList();
            final s = req.isNotEmpty ? req.first : (j.requiredSkills.isNotEmpty ? j.requiredSkills.first : null);
            return s == null ? null : 'Needs: ${s.skillName} ${s.level}';
          }()),
      ];
    }
    if (rows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.space4),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(AppSpacing.space4, AppSpacing.space3, AppSpacing.space2, AppSpacing.space2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: Text(heading, style: AppTypography.titleMedium)),
                TextButton(
                  onPressed: () => ref.read(rootTabIndexProvider.notifier).state = RootTab.jobs,
                  child: const Text('See all'),
                ),
              ],
            ),
            for (final r in rows)
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => JobDetailScreen(jobId: r.jobId)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${r.title} · ${r.org}',
                                style: AppTypography.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                            if (r.chip != null) ...[
                              const SizedBox(height: AppSpacing.space1),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space2, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  borderRadius: BorderRadius.circular(AppRadius.full),
                                ),
                                child: Text(r.chip!, style: AppTypography.labelSmall.copyWith(color: AppColors.primary)),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 20, color: AppColors.textTertiary),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
