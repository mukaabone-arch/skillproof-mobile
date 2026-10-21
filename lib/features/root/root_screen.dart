import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../account/account_status_controller.dart';
import '../assessments/assessments_controller.dart';
import '../badges/badges_controller.dart';
import '../badges/badges_screen.dart';
import '../certifications/certifications_controller.dart';
import '../entitlements/entitlements_controller.dart';
import '../home/copilot_plan_controller.dart';
import '../home/home_screen.dart';
import '../interviews/interviews_controller.dart';
import '../interviews/interviews_screen.dart';
import '../jobs/applications_controller.dart';
import '../jobs/jobs_screen.dart';
import '../jobs/matched_controller.dart';
import '../profile/profile_controller.dart';
import '../profile/profile_screen.dart';
import 'root_tab_provider.dart';

/// Post-login shell: Home is a launcher; Jobs / Badges / Interviews /
/// Profile open as pushed pages — see [RootTab] for the index each position maps to. Each tab
/// is its own Scaffold (with its own AppBar), kept alive in an
/// [IndexedStack] so switching tabs doesn't lose in-flight state like the
/// Jobs filters. The active index lives in [rootTabIndexProvider] rather
/// than local State so other screens can switch tabs programmatically.
///
/// Also owns the app-resume refetch: assessments run on the web app (see
/// core/external_link.dart), so the candidate leaves and comes back mid- or
/// post-assessment with no in-app signal of what happened out there.
/// Refetching everything on [AppLifecycleState.resumed] is what makes a
/// newly-earned badge, an in-progress card, or the Home co-pilot's next
/// suggestion show up without a manual pull-to-refresh.
class RootScreen extends ConsumerStatefulWidget {
  const RootScreen({super.key});

  @override
  ConsumerState<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends ConsumerState<RootScreen> with WidgetsBindingObserver {


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refetchAll();
  }

  void _refetchAll() {
    ref.read(profileControllerProvider.notifier).load();
    ref.read(badgesControllerProvider.notifier).load();
    ref.read(certificationsControllerProvider.notifier).load();
    ref.read(matchedControllerProvider.notifier).load();
    ref.read(applicationsControllerProvider.notifier).load();
    ref.read(assessmentsControllerProvider.notifier).load();
    ref.read(interviewsControllerProvider.notifier).load();
    ref.read(entitlementsControllerProvider.notifier).load();
    ref.read(copilotPlanControllerProvider.notifier).load();
    // Catches a deactivation made from another device/session while this
    // one was backgrounded — AccountStatusGate wraps RootScreen, so a
    // flip to deactivated here surfaces ReactivateScreen on the next build.
    ref.read(accountStatusControllerProvider.notifier).load();
  }

  /// The screen each [RootTab] opens as a full page (with its own back arrow).
  Widget _screenFor(int tab) => switch (tab) {
        RootTab.jobs => const JobsScreen(),
        RootTab.badges => const BadgesScreen(),
        RootTab.interviews => const InterviewsScreen(),
        RootTab.profile => const ProfileScreen(),
        _ => const HomeScreen(),
      };

  @override
  Widget build(BuildContext context) {
    // Home is now a launcher (see FeatureGrid) — no bottom bar. Any code that
    // sets rootTabIndexProvider (the grid, Close-the-gap, "Go to Profile")
    // lands here: return to Home, then push that feature as its own page.
    // Reset to home afterwards so tapping the same feature again still fires.
    ref.listen<int>(rootTabIndexProvider, (previous, next) {
      if (next == RootTab.home) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(rootTabIndexProvider.notifier).state = RootTab.home;
        final nav = Navigator.of(context);
        nav.popUntil((route) => route.isFirst);
        nav.push(MaterialPageRoute<void>(builder: (_) => _screenFor(next)));
      });
    });

    return const HomeScreen();
  }
}
