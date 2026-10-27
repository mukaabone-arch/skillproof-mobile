import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/greeting.dart';
import '../../../models/matched_job.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
import '../../badges/badges_controller.dart';
import '../../badges/badges_highlight_provider.dart';
import '../../badges/badges_state.dart';
import '../../certifications/certifications_controller.dart';
import '../../certifications/certifications_state.dart';
import '../../jobs/applications_controller.dart';
import '../../jobs/job_detail_screen.dart';
import '../../jobs/jobs_state.dart';
import '../../jobs/matched_controller.dart';
import '../../profile/profile_controller.dart';
import '../../profile/profile_state.dart';
import '../../root/root_tab_provider.dart';
import '../copilot_plan_controller.dart';
import 'copilot_panel.dart';

/// Greeting + journey stepper + AI co-pilot panel — one cohesive unit
/// because all five signals (profile, badges, certifications,
/// matched jobs, applications) are derived together, so they can never
/// disagree about where the candidate is in their journey or what the
/// co-pilot suggests next. Shown as a single loading/error unit rather than
/// independently-flickering pieces, since none of them means anything
/// without the others.
class HeroSection extends ConsumerWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    final badgesState = ref.watch(badgesControllerProvider);
    final certificationsState = ref.watch(certificationsControllerProvider);
    final applicationsState = ref.watch(applicationsControllerProvider);
    final matchedState = ref.watch(matchedControllerProvider);
    // Fetched in parallel with the five above. Counted as loading (not
    // rendered early from the on-device fallback) so the card never flips
    // from one suggestion to a different one a moment later.
    final planState = ref.watch(copilotPlanControllerProvider);

    final loading = planState is CopilotPlanLoading ||
        profileState is ProfileLoading ||
        badgesState is BadgesLoading ||
        certificationsState is CertificationsLoading ||
        applicationsState is ApplicationsLoading ||
        matchedState is MatchedLoading;
    if (loading) return const _HeroSkeleton();

    String? errorMessage;
    if (profileState is ProfileError) {
      errorMessage = profileState.message;
    } else if (badgesState is BadgesError) {
      errorMessage = badgesState.message;
    } else if (certificationsState is CertificationsError) {
      errorMessage = certificationsState.message;
    } else if (applicationsState is ApplicationsError) {
      errorMessage = applicationsState.message;
    } else if (matchedState is MatchedError) {
      errorMessage = matchedState.message;
    }
    if (errorMessage != null) {
      return _HeroError(
        message: errorMessage,
        onRetry: () {
          ref.read(profileControllerProvider.notifier).load();
          ref.read(badgesControllerProvider.notifier).load();
          ref.read(certificationsControllerProvider.notifier).load();
          ref.read(applicationsControllerProvider.notifier).load();
          ref.read(matchedControllerProvider.notifier).load();
          ref.read(copilotPlanControllerProvider.notifier).load();
        },
      );
    }

    final profile = (profileState as ProfileLoaded).profile;
    final badgeCount = (badgesState as BadgesLoaded).badges.length;
    final verifiedCertificationCount =
        (certificationsState as CertificationsLoaded).certifications.where((c) => c.isVerified).length;
    final applicationCount = (applicationsState as ApplicationsLoaded).applications.length;
    final matchedJobs = (matchedState as MatchedLoaded).jobs;

    final hasProfile = profile.completeness > 0;
    // "Verified skill" for journey purposes is either proof tier — a
    // MyAmbii badge or a verified certification — matching the
    // apply-gate's own either/or rule. This never leaks into scoring or
    // into any green-colored element; see StatusCards for how the two
    // tiers stay visually distinct even while being summed here.
    final hasVerifiedSkill = badgeCount > 0 || verifiedCertificationCount > 0;
    final hasApplied = applicationCount > 0;
    // Nothing built a profile, earned proof, or applied to anything yet —
    // same derivation as the web dashboard's isFirstSession, no new field.
    final isFirstSession = !hasProfile && !hasVerifiedSkill && !hasApplied;

    // Profile basics + first verified skill — the checklist's two open steps.
    final stepsLeft = (profile.readyToApply ? 0 : 1) + (hasVerifiedSkill ? 0 : 1);

    // Server plan first (same suggestion as the website, including interview,
    // employer-invite and review states); the on-device ladder only when the
    // plan endpoint is unavailable.
    final planStep =
        planState is CopilotPlanLoaded && planState.plan.steps.isNotEmpty ? planState.plan.steps.first : null;
    final copilot = planStep != null
        ? copilotMessageFromStep(planStep)
        : buildCopilotMessage(
            hasProfile: hasProfile,
            hasVerifiedSkill: hasVerifiedSkill,
            bestUnapplied: _bestUnapplied(matchedJobs),
            recurringGap: _recurringGap(matchedJobs),
            hasApplied: hasApplied,
            applicationCount: applicationCount,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _greeting(fullName: profile.fullName, isFirstSession: isFirstSession),
          style: AppTypography.headlineSmall,
        ),
        if (stepsLeft > 0) ...[
          const SizedBox(height: AppSpacing.space1),
          Text(
            '$stepsLeft step${stepsLeft == 1 ? '' : 's'} to your first job match.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
        ],
        const SizedBox(height: AppSpacing.space4),
        const SizedBox(height: AppSpacing.space4),
        CopilotPanel(message: copilot, onTap: () => _handleCopilotAction(context, ref, copilot)),
      ],
    );
  }

  /// Never shows the raw phone/email as a "name" — greets by fullName once
  /// it exists, otherwise a neutral greeting that still distinguishes a
  /// brand new visitor from someone returning who just hasn't named
  /// themselves yet. Both nameless branches are time-of-day based, same as
  /// the named branch — mirrors apps/web/lib/greeting.ts + Dashboard.tsx's
  /// identical change, kept in step deliberately so the two platforms never
  /// show different copy for the same state.
  String _greeting({required String? fullName, required bool isFirstSession}) {
    final trimmed = fullName?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return '${timeOfDayGreeting()}, $trimmed';
    if (isFirstSession) return '${timeOfDayGreeting()} — welcome to MyAmbii';
    return '${timeOfDayGreeting()} — welcome back';
  }

  /// Highest-scoring match the candidate hasn't already applied to —
  /// sorted rather than just taking the API's own order, since /jobs/matched
  /// doesn't guarantee it's sorted by score.
  MatchedJob? _bestUnapplied(List<MatchedJob> jobs) {
    final sorted = [...jobs]..sort((a, b) => b.score.compareTo(a.score));
    for (final j in sorted) {
      if (!j.job.alreadyApplied) return j;
    }
    return null;
  }

  /// How often each missing skill blocks one of the candidate's top 5
  /// matches — surfaced only once it recurs (kRecurringGapMinCount), so the
  /// co-pilot points at an actual bottleneck rather than one job's
  /// idiosyncratic requirement.
  RecurringGap? _recurringGap(List<MatchedJob> jobs) {
    final sorted = [...jobs]..sort((a, b) => b.score.compareTo(a.score));
    final gapCounts = <String, int>{};
    final gapSkillIds = <String, String>{};
    for (final j in sorted.take(5)) {
      for (final m in j.missing) {
        gapCounts[m.skillName] = (gapCounts[m.skillName] ?? 0) + 1;
        gapSkillIds[m.skillName] = m.skillId;
      }
    }
    RecurringGap? result;
    gapCounts.forEach((name, count) {
      if (count >= kRecurringGapMinCount && (result == null || count > result!.count)) {
        result = RecurringGap(skillId: gapSkillIds[name]!, skillName: name, count: count);
      }
    });
    return result;
  }

  void _handleCopilotAction(BuildContext context, WidgetRef ref, CopilotMessage message) {
    switch (message.action) {
      case CopilotAction.profileTab:
        ref.read(rootTabIndexProvider.notifier).state = RootTab.profile;
      case CopilotAction.badgesTab:
        if (message.skillId != null) {
          ref.read(badgesHighlightSkillIdProvider.notifier).state = message.skillId;
        }
        ref.read(rootTabIndexProvider.notifier).state = RootTab.badges;
      case CopilotAction.jobsTab:
        ref.read(rootTabIndexProvider.notifier).state = RootTab.jobs;
      case CopilotAction.jobDetail:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => JobDetailScreen(jobId: message.jobId!)),
        );
      case CopilotAction.interviewsTab:
        ref.read(rootTabIndexProvider.notifier).state = RootTab.interviews;
      case CopilotAction.none:
        break;
    }
  }
}

class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: AppSpacing.space3),
          Expanded(child: Text('Loading your dashboard…', style: AppTypography.bodyMedium)),
        ],
      ),
    );
  }
}

class _HeroError extends StatelessWidget {
  const _HeroError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: AppTypography.bodyMedium.copyWith(color: AppColors.errorBright)),
          const SizedBox(height: AppSpacing.space3),
          AppButton(label: 'Retry', variant: AppButtonVariant.secondary, onPressed: onRetry),
        ],
      ),
    );
  }
}
