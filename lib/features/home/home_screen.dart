import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../auth/auth_controller.dart';
import '../badges/badges_controller.dart';
import '../badges/badges_state.dart';
import '../certifications/certifications_controller.dart';
import '../certifications/certifications_state.dart';
import '../entitlements/entitlements_controller.dart';
import '../jobs/applications_controller.dart';
import '../jobs/jobs_state.dart';
import '../jobs/matched_controller.dart';
import '../profile/profile_controller.dart';
import '../profile/profile_state.dart';
import '../root/root_tab_provider.dart';
import 'copilot_plan_controller.dart';
import 'widgets/hero_section.dart';
import 'widgets/jobs_close_to.dart';
import 'widgets/onboarding_checklist.dart';
import 'widgets/status_cards.dart';

/// Candidate dashboard: greeting + one next step (HeroSection's co-pilot),
/// a short "what's left" checklist while onboarding, the jobs they're
/// closest to, and the status numbers — the last only once there's
/// progress to report (no "0%, 0, 0" wall on day one). Navigation lives in
/// RootScreen's bottom bar; log-out sits behind the avatar menu. Every
/// section loads and fails independently, reusing the existing controllers.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watched only so entitlements are fetched at app start (Home is the
    // first child RootScreen's IndexedStack builds).
    ref.watch(entitlementsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image(image: AssetImage('assets/images/myambii-logo.png'), height: 28, width: 28),
            SizedBox(width: AppSpacing.space2),
            Text('MyAmbii'),
          ],
        ),
        actions: const [_AccountMenu()],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(profileControllerProvider.notifier).load(),
            ref.read(badgesControllerProvider.notifier).load(),
            ref.read(certificationsControllerProvider.notifier).load(),
            ref.read(matchedControllerProvider.notifier).load(),
            ref.read(applicationsControllerProvider.notifier).load(),
            ref.read(entitlementsControllerProvider.notifier).load(),
            ref.read(copilotPlanControllerProvider.notifier).load(),
          ]);
          ref.invalidate(homeJobsPreviewProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.space4, AppSpacing.space4, AppSpacing.space4, AppSpacing.space6),
          children: const [
            HeroSection(),
            OnboardingChecklist(),
            JobsCloseTo(),
            _ProgressStats(),
          ],
        ),
      ),
    );
  }
}

/// StatusCardsRow, but only once there's something to count — a verified
/// skill or an application. Before that, the checklist says it better.
class _ProgressStats extends ConsumerWidget {
  const _ProgressStats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badges = ref.watch(badgesControllerProvider);
    final certs = ref.watch(certificationsControllerProvider);
    final apps = ref.watch(applicationsControllerProvider);
    final hasProgress = (badges is BadgesLoaded && badges.badges.isNotEmpty) ||
        (certs is CertificationsLoaded && certs.certifications.any((c) => c.isVerified)) ||
        (apps is ApplicationsLoaded && apps.applications.isNotEmpty);
    if (!hasProgress) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.only(top: AppSpacing.space5),
      child: StatusCardsRow(),
    );
  }
}

/// Avatar (initials once there's a name) → Profile & account, or Log out.
/// Replaces the bare log-out icon that sat on the dashboard.
class _AccountMenu extends ConsumerWidget {
  const _AccountMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    final name = profileState is ProfileLoaded ? profileState.profile.fullName?.trim() ?? '' : '';
    final initials = name.isEmpty
        ? ''
        : name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2).map((p) => p[0].toUpperCase()).join();

    return PopupMenuButton<String>(
      tooltip: 'Account',
      position: PopupMenuPosition.under,
      onSelected: (value) {
        if (value == 'profile') {
          ref.read(rootTabIndexProvider.notifier).state = RootTab.profile;
        } else if (value == 'logout') {
          ref.read(authControllerProvider.notifier).logout();
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'profile', child: Text('Profile & account')),
        PopupMenuItem(value: 'logout', child: Text('Log out')),
      ],
      child: Padding(
        padding: const EdgeInsets.only(right: AppSpacing.space4),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.primarySoft,
          child: initials.isEmpty
              ? const Icon(Icons.person_outline, size: 18, color: AppColors.primary)
              : Text(initials, style: AppTypography.labelSmall.copyWith(color: AppColors.primary)),
        ),
      ),
    );
  }
}
