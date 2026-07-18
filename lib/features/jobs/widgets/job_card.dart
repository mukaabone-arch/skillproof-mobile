import 'package:flutter/material.dart';

import '../../../models/job.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_card.dart';

/// Summary card shared by the Browse and Matched tabs. [trailing] carries
/// the tab-specific bit ([ScoreBar] for Matched, nothing for Browse);
/// "Applied" is shown consistently across both since it's true regardless
/// of tab. Deliberately brand, not green — an application's status isn't
/// a verified-skill signal (see the color rule on AppColors).
class JobCard extends StatelessWidget {
  const JobCard({required this.job, this.trailing, this.onTap, this.child, super.key});

  final Job job;
  final Widget? trailing;
  final VoidCallback? onTap;
  /// Extra content rendered below the skills/applied lines — e.g. a row of
  /// [SkillBadge]s for verified matched skills on the "Matched to you" tab.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(job.title, style: AppTypography.titleMedium)),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(_metaLine(job), style: AppTypography.bodySmall),
          if (job.requiredSkills.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space2),
            Text(
              'Skills: ${job.requiredSkills.map((s) => s.skillName).join(', ')}',
              style: AppTypography.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (job.alreadyApplied) ...[
            const SizedBox(height: AppSpacing.space2),
            Text('✓ Applied', style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
          ],
          if (child != null) ...[
            const SizedBox(height: AppSpacing.space2),
            child!,
          ],
        ],
      ),
    );
  }

  String _metaLine(Job job) {
    final parts = <String>[
      job.orgName,
      job.employmentType.replaceAll('_', ' '),
      job.remote ? 'Remote' : (job.location?.isNotEmpty == true ? job.location! : 'Location not set'),
    ];
    if (job.experienceMin != null || job.experienceMax != null) {
      parts.add('${job.experienceMin ?? 0}–${job.experienceMax ?? '∞'} yrs');
    }
    return parts.join(' · ');
  }
}
