import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which bottom-nav tab is active in [RootScreen] (0=Home, 1=Jobs,
/// 2=Badges, 3=Profile) — a provider rather than [RootScreen]'s own local
/// State, so other screens can switch tabs programmatically: Profile's
/// verified-badge count links straight to the Badges tab, and a job's
/// PROFILE_INCOMPLETE prompt jumps to the Profile tab.
final rootTabIndexProvider = StateProvider<int>((ref) => 0);
