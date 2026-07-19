import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../assessments/assessments_controller.dart';
import '../badges/badges_controller.dart';
import '../badges/badges_screen.dart';
import '../external_credentials/external_credentials_controller.dart';
import '../home/home_screen.dart';
import '../jobs/applications_controller.dart';
import '../jobs/jobs_screen.dart';
import '../jobs/matched_controller.dart';
import '../profile/profile_controller.dart';
import '../profile/profile_screen.dart';
import 'root_tab_provider.dart';

/// Post-login shell: bottom nav across Home / Jobs / Badges / Profile. Each
/// tab is its own Scaffold (with its own AppBar), kept alive in an
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
  static const _tabs = [
    HomeScreen(),
    JobsScreen(),
    BadgesScreen(),
    ProfileScreen(),
  ];

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
    ref.read(externalCredentialsControllerProvider.notifier).load();
    ref.read(matchedControllerProvider.notifier).load();
    ref.read(applicationsControllerProvider.notifier).load();
    ref.read(assessmentsControllerProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(rootTabIndexProvider);

    return Scaffold(
      body: IndexedStack(index: index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => ref.read(rootTabIndexProvider.notifier).state = i,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.work_outline), selectedIcon: Icon(Icons.work), label: 'Jobs'),
          NavigationDestination(icon: Icon(Icons.verified_outlined), selectedIcon: Icon(Icons.verified), label: 'Badges'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
