import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
import '../../badges/badges_controller.dart';
import '../../badges/badges_state.dart';
import '../../external_credentials/external_credentials_controller.dart';
import '../../external_credentials/external_credentials_state.dart';
import '../../jobs/applications_controller.dart';
import '../../jobs/jobs_state.dart';
import '../../profile/profile_controller.dart';
import '../../profile/profile_state.dart';
import '../../root/root_tab_provider.dart';
import 'journey_progress.dart';
import 'next_step_card.dart';

/// Greeting + journey stepper + next-step prompt — one cohesive unit
/// because all three are derived from the exact same four signals
/// (profile, badges, external credentials, applications), so they can
/// never disagree about where the candidate is in their journey. Shown as
/// a single loading/error unit rather than three independently-flickering
/// pieces, since none of the three means anything without the others.
class HeroSection extends ConsumerWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    final badgesState = ref.watch(badgesControllerProvider);
    final credentialsState = ref.watch(externalCredentialsControllerProvider);
    final applicationsState = ref.watch(applicationsControllerProvider);

    final loading = profileState is ProfileLoading ||
        badgesState is BadgesLoading ||
        credentialsState is ExternalCredentialsLoading ||
        applicationsState is ApplicationsLoading;
    if (loading) return const _HeroSkeleton();

    String? errorMessage;
    if (profileState is ProfileError) {
      errorMessage = profileState.message;
    } else if (badgesState is BadgesError) {
      errorMessage = badgesState.message;
    } else if (credentialsState is ExternalCredentialsError) {
      errorMessage = credentialsState.message;
    } else if (applicationsState is ApplicationsError) {
      errorMessage = applicationsState.message;
    }
    if (errorMessage != null) {
      return _HeroError(
        message: errorMessage,
        onRetry: () {
          ref.read(profileControllerProvider.notifier).load();
          ref.read(badgesControllerProvider.notifier).load();
          ref.read(externalCredentialsControllerProvider.notifier).load();
          ref.read(applicationsControllerProvider.notifier).load();
        },
      );
    }

    final profile = (profileState as ProfileLoaded).profile;
    final badgeCount = (badgesState as BadgesLoaded).badges.length;
    final verifiedCredentialCount =
        (credentialsState as ExternalCredentialsLoaded).credentials.where((c) => c.isVerified).length;
    final applicationCount = (applicationsState as ApplicationsLoaded).applications.length;

    final hasProfile = profile.completeness > 0;
    // "Verified skill" for journey purposes is either proof tier — a
    // SkillProof badge or a verified external credential — matching the
    // apply-gate's own either/or rule. This never leaks into scoring or
    // into any green-colored element; see StatusCards for how the two
    // tiers stay visually distinct even while being summed here.
    final hasVerifiedSkill = badgeCount > 0 || verifiedCredentialCount > 0;
    final hasApplied = applicationCount > 0;
    // Nothing built a profile, earned proof, or applied to anything yet —
    // same derivation as the web dashboard's isFirstSession, no new field.
    final isFirstSession = !hasProfile && !hasVerifiedSkill && !hasApplied;

    final stage1 = hasProfile ? JourneyStepState.done : JourneyStepState.active;
    final stage2 = hasVerifiedSkill
        ? JourneyStepState.done
        : (hasProfile ? JourneyStepState.active : JourneyStepState.upcoming);
    final stage3 = hasApplied
        ? JourneyStepState.done
        : (hasVerifiedSkill ? JourneyStepState.active : JourneyStepState.upcoming);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _greeting(fullName: profile.fullName, isFirstSession: isFirstSession),
          style: AppTypography.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.space4),
        JourneyProgress(steps: [
          JourneyStep(label: 'Profile built', state: stage1),
          JourneyStep(label: 'First badge', state: stage2),
          JourneyStep(label: 'Jobs explored', state: stage3),
        ]),
        const SizedBox(height: AppSpacing.space4),
        NextStepCard(step: _nextStep(ref: ref, hasProfile: hasProfile, hasVerifiedSkill: hasVerifiedSkill)),
      ],
    );
  }

  /// Never shows the raw phone/email as a "name" — greets by fullName once
  /// it exists, otherwise a neutral greeting that still distinguishes a
  /// brand new visitor from someone returning who just hasn't named
  /// themselves yet.
  String _greeting({required String? fullName, required bool isFirstSession}) {
    final trimmed = fullName?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return 'Welcome, $trimmed';
    if (isFirstSession) return 'Welcome to SkillProof';
    return 'Welcome back';
  }

  NextStep _nextStep({
    required WidgetRef ref,
    required bool hasProfile,
    required bool hasVerifiedSkill,
  }) {
    if (!hasProfile) {
      return NextStep(
        kicker: 'Your next step',
        title: "Complete your profile so employers know who they're looking at.",
        ctaLabel: 'Complete your profile',
        onTap: () => ref.read(rootTabIndexProvider.notifier).state = 3, // Profile tab
      );
    }
    if (!hasVerifiedSkill) {
      return NextStep(
        kicker: 'Your next step',
        title: 'Earn a badge or add a credential to prove your skills.',
        ctaLabel: 'Earn a badge or add a credential',
        onTap: () => ref.read(rootTabIndexProvider.notifier).state = 2, // Badges tab
      );
    }
    return NextStep(
      kicker: "You're verified",
      title: 'See jobs that match your verified skills.',
      ctaLabel: 'Explore matched jobs',
      onTap: () => ref.read(rootTabIndexProvider.notifier).state = 1, // Jobs tab
    );
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
          Text(message, style: AppTypography.bodyMedium.copyWith(color: AppColors.dangerBright)),
          const SizedBox(height: AppSpacing.space3),
          AppButton(label: 'Retry', variant: AppButtonVariant.secondary, onPressed: onRetry),
        ],
      ),
    );
  }
}
