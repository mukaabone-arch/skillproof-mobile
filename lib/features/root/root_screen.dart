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

/// Post-login shell: a bottom bar (Home · Skills · Jobs · Interviews ·
/// Profile) over an [IndexedStack], so each tab keeps its state (Jobs
/// filters, scroll position) while you move between them. The active tab
/// lives in [rootTabIndexProvider] so any screen can switch tabs — the
/// co-pilot's CTA, "Close the gap", a job's PROFILE_INCOMPLETE prompt.
/// Bar order differs from the [RootTab] index values on purpose; [_order]
/// is the single place that maps one to the other.
///
/// Also owns the app-resume refetch: skill checks run on the web app (see
/// core/external_link.dart), so the candidate leaves and comes back mid- or
/// post-check with no in-app signal of what happened out there. Refetching
/// everything on [AppLifecycleState.resumed] is what makes a newly-earned
/// badge, an in-progress card, or Home's next suggestion show up without a
/// manual pull-to-refresh.
class RootScreen extends ConsumerStatefulWidget {
  const RootScreen({super.key});

  @override
  ConsumerState<RootScreen> createState() => _RootScreenState();
}

const List<int> _order = [RootTab.home, RootTab.badges, RootTab.jobs, RootTab.interviews, RootTab.profile];

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

  @override
  Widget build(BuildContext context) {
    // A tab switch requested from a pushed page (e.g. a job detail's "Go to
    // Profile") must close that page first, or the tab changes underneath it.
    ref.listen<int>(rootTabIndexProvider, (previous, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      });
    });

    final tab = ref.watch(rootTabIndexProvider);
    final position = _order.indexOf(tab).clamp(0, _order.length - 1);

    // Android back on another tab returns to Home instead of leaving the app.
    return PopScope(
      canPop: tab == RootTab.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) ref.read(rootTabIndexProvider.notifier).state = RootTab.home;
      },
      child: Scaffold(
        body: IndexedStack(
          index: position,
          children: const [
            HomeScreen(),
            BadgesScreen(),
            JobsScreen(),
            InterviewsScreen(),
            ProfileScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: position,
          onDestinationSelected: (i) => ref.read(rootTabIndexProvider.notifier).state = _order[i],
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(
                icon: Icon(Icons.verified_outlined), selectedIcon: Icon(Icons.verified), label: 'Skills'),
            NavigationDestination(icon: Icon(Icons.work_outline), selectedIcon: Icon(Icons.work), label: 'Jobs'),
            NavigationDestination(
                icon: Icon(Icons.event_note_outlined), selectedIcon: Icon(Icons.event_note), label: 'Interviews'),
            NavigationDestination(
                icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
