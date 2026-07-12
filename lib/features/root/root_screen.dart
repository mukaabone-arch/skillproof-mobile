import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../badges/badges_screen.dart';
import '../home/home_screen.dart';
import '../jobs/jobs_screen.dart';
import '../profile/profile_screen.dart';
import 'root_tab_provider.dart';

/// Post-login shell: bottom nav across Home / Jobs / Badges / Profile. Each
/// tab is its own Scaffold (with its own AppBar), kept alive in an
/// [IndexedStack] so switching tabs doesn't lose in-flight state like the
/// Jobs filters. The active index lives in [rootTabIndexProvider] rather
/// than local State so other screens can switch tabs programmatically.
class RootScreen extends ConsumerWidget {
  const RootScreen({super.key});

  static const _tabs = [
    HomeScreen(),
    JobsScreen(),
    BadgesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
