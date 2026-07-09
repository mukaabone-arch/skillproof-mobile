import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/job.dart';
import 'job_detail_controller.dart';
import 'jobs_state.dart';

class JobDetailScreen extends ConsumerWidget {
  const JobDetailScreen({required this.jobId, super.key});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(jobDetailControllerProvider(jobId));

    return Scaffold(
      appBar: AppBar(title: const Text('Job details')),
      body: switch (state) {
        JobDetailLoading() => const Center(child: CircularProgressIndicator()),
        JobDetailError(:final message) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => ref.read(jobDetailControllerProvider(jobId).notifier).load(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        JobDetailLoaded() => _JobDetailBody(jobId: jobId, state: state),
      },
    );
  }
}

class _JobDetailBody extends ConsumerWidget {
  const _JobDetailBody({required this.jobId, required this.state});

  final String jobId;
  final JobDetailLoaded state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final job = state.job;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(job.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(_metaLine(job), style: Theme.of(context).textTheme.bodyMedium),
        if (job.salaryMin != null || job.salaryMax != null) ...[
          const SizedBox(height: 6),
          Text('Salary: ${job.salaryMin ?? '?'}–${job.salaryMax ?? '?'}'),
        ],
        if (job.requiredSkills.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Required skills', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: job.requiredSkills
                .map((s) => Chip(
                      label: Text('${s.skillName} (${s.level}${s.isRequired ? '' : ', optional'})'),
                    ))
                .toList(),
          ),
        ],
        if (job.description != null && job.description!.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Description', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(job.description!),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            FilledButton(
              onPressed: (state.applying || job.alreadyApplied)
                  ? null
                  : () => ref.read(jobDetailControllerProvider(jobId).notifier).apply(),
              child: Text(
                job.alreadyApplied ? 'Applied' : (state.applying ? 'Applying…' : 'Apply'),
              ),
            ),
            if (job.alreadyApplied) ...[
              const SizedBox(width: 12),
              Text(
                "✓ You've applied to this job",
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ],
        ),
        if (state.applyIssueCode == 'PROFILE_INCOMPLETE') ...[
          const SizedBox(height: 16),
          const _ActionableNotice(
            message: 'Almost there — add your name and either a headline or years of '
                'experience so this employer knows who they\'re reviewing. '
                'Complete your profile from the Profile tab, then come back and apply.',
          ),
        ],
        if (state.applyIssueCode == 'BADGE_REQUIRED') ...[
          const SizedBox(height: 16),
          _ActionableNotice(
            message: state.applyIssueMessage ??
                'Earn at least one verified skill badge before applying — take an '
                    'assessment to get started.',
          ),
        ],
        if (state.applyError != null) ...[
          const SizedBox(height: 16),
          Text(state.applyError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
      ],
    );
  }

  String _metaLine(Job job) {
    final parts = <String>[
      job.orgName,
      job.employmentType.replaceAll('_', ' '),
      job.remote ? 'Remote' : (job.location?.isNotEmpty == true ? job.location! : 'Location not set'),
    ];
    if (job.experienceMin != null || job.experienceMax != null) {
      parts.add('${job.experienceMin ?? 0}–${job.experienceMax ?? '∞'} yrs experience');
    }
    return parts.join(' · ');
  }
}

/// Actionable prompt shown for apply-time issues the candidate can resolve
/// themselves (PROFILE_INCOMPLETE / BADGE_REQUIRED) — styled distinctly
/// from [state.applyError] so it doesn't read as a raw failure.
class _ActionableNotice extends StatelessWidget {
  const _ActionableNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(message),
    );
  }
}
