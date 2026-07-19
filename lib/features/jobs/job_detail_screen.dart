import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/job.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/job_description.dart';
import '../root/root_tab_provider.dart';
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
              padding: const EdgeInsets.all(AppSpacing.space6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.errorBright),
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  AppButton(
                    label: 'Retry',
                    variant: AppButtonVariant.secondary,
                    onPressed: () => ref.read(jobDetailControllerProvider(jobId).notifier).load(),
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
      padding: const EdgeInsets.all(AppSpacing.space4),
      children: [
        Text(job.title, style: AppTypography.headlineSmall),
        const SizedBox(height: AppSpacing.space2),
        Text(_metaLine(job), style: AppTypography.bodyMedium),
        if (job.salaryMin != null || job.salaryMax != null) ...[
          const SizedBox(height: AppSpacing.space2),
          Text('Salary: ${job.salaryMin ?? '?'}–${job.salaryMax ?? '?'}', style: AppTypography.bodyMedium),
        ],
        // Required skills are job *requirements*, not the candidate's own
        // verified skills — deliberately a neutral chip (via the app-wide
        // ChipThemeData), not SkillBadge/success-green. Green is reserved
        // exclusively for skills the candidate has actually verified.
        if (job.requiredSkills.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space6),
          Text('Required skills', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.space3),
          Wrap(
            spacing: AppSpacing.space2,
            runSpacing: AppSpacing.space2,
            children: job.requiredSkills
                .map((s) => Chip(label: Text('${s.skillName} (${s.level}${s.isRequired ? '' : ', optional'})')))
                .toList(),
          ),
        ],
        if (job.description != null && job.description!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space6),
          Text('Description', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.space3),
          JobDescription(description: job.description!),
        ],
        const SizedBox(height: AppSpacing.space7),
        Row(
          children: [
            AppButton(
              label: job.alreadyApplied ? 'Applied' : 'Apply',
              busy: state.applying,
              onPressed: job.alreadyApplied ? null : () => ref.read(jobDetailControllerProvider(jobId).notifier).apply(),
            ),
            if (job.alreadyApplied) ...[
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Text(
                  "✓ You've applied to this job",
                  style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ],
        ),
        if (state.applyIssueCode == 'PROFILE_INCOMPLETE') ...[
          const SizedBox(height: AppSpacing.space4),
          _ActionableNotice(
            message: 'Almost there — add your name and either a headline or years of '
                'experience so this employer knows who they\'re reviewing.',
            actionLabel: 'Go to Profile',
            onAction: () {
              // Switch the bottom nav to the Profile tab and pop back to
              // root so the candidate actually lands on it — this screen
              // was pushed with Navigator.push, on top of the IndexedStack
              // the bottom nav controls, so switching the tab alone
              // wouldn't be visible until this route is also dismissed.
              ref.read(rootTabIndexProvider.notifier).state = RootTab.profile;
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
        if (state.applyIssueCode == 'BADGE_REQUIRED') ...[
          const SizedBox(height: AppSpacing.space4),
          _ActionableNotice(
            message: state.applyIssueMessage ??
                'Earn at least one verified skill badge before applying — take an '
                    'assessment to get started.',
          ),
        ],
        if (state.applyError != null) ...[
          const SizedBox(height: AppSpacing.space4),
          Text(state.applyError!, style: AppTypography.bodyMedium.copyWith(color: AppColors.errorBright)),
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
/// from [state.applyError] so it doesn't read as a raw failure. Indigo, not
/// green: this is guidance text about *earning* a badge, not a verified
/// skill/badge/certificate itself, so it stays out of the success-green
/// color family per the rule on AppColors.
class _ActionableNotice extends StatelessWidget {
  const _ActionableNotice({required this.message, this.actionLabel, this.onAction});

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.space3),
            AppButton(label: actionLabel!, variant: AppButtonVariant.secondary, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}
