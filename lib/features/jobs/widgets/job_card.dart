import 'package:flutter/material.dart';

import '../../../models/job.dart';

/// Summary card shared by the Browse and Matched tabs. [trailing] carries
/// the tab-specific bit (score for Matched, nothing for Browse); "Applied"
/// is shown consistently across both since it's true regardless of tab.
class JobCard extends StatelessWidget {
  const JobCard({required this.job, this.trailing, this.onTap, super.key});

  final Job job;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      job.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
              const SizedBox(height: 4),
              Text(_metaLine(job), style: Theme.of(context).textTheme.bodySmall),
              if (job.requiredSkills.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Skills: ${job.requiredSkills.map((s) => s.skillName).join(', ')}',
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (job.alreadyApplied) ...[
                const SizedBox(height: 6),
                Text(
                  '✓ Applied',
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ],
            ],
          ),
        ),
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
