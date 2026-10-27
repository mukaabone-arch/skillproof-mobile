import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/assessment_catalog_entry.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_card.dart';
import '../../assessments/assessments_controller.dart';
import '../../assessments/assessments_state.dart';
import '../../badges/badges_controller.dart';
import '../../badges/badges_state.dart';
import '../../certifications/certifications_controller.dart';
import '../../certifications/certifications_state.dart';
import '../../profile/profile_controller.dart';
import '../../profile/profile_state.dart';
import '../../root/root_tab_provider.dart';

/// "What's left before your first job match": account → profile basics →
/// first skill check. Shown only until the first verified skill (badge or
/// verified certification — the same either/or as HeroSection), then gone.
/// Ticks use brand colour, not green: green is reserved for MyAmbii badges.
class OnboardingChecklist extends ConsumerWidget {
  const OnboardingChecklist({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    final badgesState = ref.watch(badgesControllerProvider);
    final certsState = ref.watch(certificationsControllerProvider);
    if (profileState is! ProfileLoaded || badgesState is! BadgesLoaded || certsState is! CertificationsLoaded) {
      return const SizedBox.shrink();
    }
    final hasVerifiedSkill =
        badgesState.badges.isNotEmpty || certsState.certifications.any((c) => c.isVerified);
    if (hasVerifiedSkill) return const SizedBox.shrink();

    final profileReady = profileState.profile.readyToApply;

    // "unlocks N jobs": the most roles any one open skill check is required
    // on (relevanceCount from the catalog). Omitted when unknown or zero.
    final assessments = ref.watch(assessmentsControllerProvider);
    var unlocks = 0;
    if (assessments is AssessmentsLoaded) {
      for (final e in assessments.entries) {
        if (e.state == AssessmentCatalogState.available && e.relevanceCount > unlocks) unlocks = e.relevanceCount;
      }
    }

    void go(int tab) => ref.read(rootTabIndexProvider.notifier).state = tab;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.space4),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4, vertical: AppSpacing.space2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Item(label: 'Account created', done: true),
            _Item(
              label: 'Profile — name, headline, experience',
              done: profileReady,
              onTap: () => go(RootTab.profile),
            ),
            _Item(
              label: 'First skill check',
              extra: unlocks > 0 ? 'unlocks $unlocks job${unlocks == 1 ? '' : 's'}' : null,
              done: false,
              onTap: () => go(RootTab.badges),
            ),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.label, required this.done, this.extra, this.onTap});

  final String label;
  final bool done;
  final String? extra;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tappable = !done && onTap != null;
    return InkWell(
      onTap: tappable ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
        child: Row(
          children: [
            Icon(
              done ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 20,
              color: done ? AppColors.primary : AppColors.textTertiary,
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: label,
                  children: [
                    if (extra != null)
                      TextSpan(text: ' · $extra', style: const TextStyle(color: AppColors.primary)),
                  ],
                ),
                style: AppTypography.bodyMedium.copyWith(
                  color: done ? AppColors.textSecondary : AppColors.textPrimary,
                ),
              ),
            ),
            if (tappable) const Icon(Icons.chevron_right, size: 20, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
