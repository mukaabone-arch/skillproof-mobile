import 'package:flutter/material.dart';

import '../home/home_screen.dart';
import '../jobs/jobs_screen.dart';
import '../profile/profile_placeholder_screen.dart';

/// Post-login shell: bottom nav across Home / Jobs / Profile. Each tab is
/// its own Scaffold (with its own AppBar), kept alive in an [IndexedStack]
/// so switching tabs doesn't lose in-flight state like the Jobs filters.
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 0;

  static const _tabs = [
    HomeScreen(),
    JobsScreen(),
    ProfilePlaceholderScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.work_outline), selectedIcon: Icon(Icons.work), label: 'Jobs'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
