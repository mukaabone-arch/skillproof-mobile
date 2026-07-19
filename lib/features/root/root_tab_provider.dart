import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Named bottom-nav tab indices — every jump-to-tab call site should use
/// these rather than a bare int. A reorder (Profile moving to last is what
/// prompted adding this) can then be done by changing this class plus
/// [RootScreen]'s destination/tab order, with the compiler pointing at
/// every call site in between rather than a grep-and-hope.
abstract final class RootTab {
  static const int home = 0;
  static const int jobs = 1;
  static const int badges = 2;
  static const int interviews = 3;
  static const int profile = 4;
}

/// Which bottom-nav tab is active in [RootScreen] — a provider rather than
/// [RootScreen]'s own local State, so other screens can switch tabs
/// programmatically: Profile's verified-badge count links straight to the
/// Badges tab, and a job's PROFILE_INCOMPLETE prompt jumps to the Profile
/// tab. See [RootTab] for the current index-to-tab mapping.
final rootTabIndexProvider = StateProvider<int>((ref) => RootTab.home);
