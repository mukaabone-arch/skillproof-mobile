import '../root/root_tab_provider.dart';

/// Data-payload `route` -> bottom-nav tab. The API's phase-2 sender uses
/// exactly these names; an unknown or missing route opens Home rather than
/// doing nothing, so a tap always lands somewhere.
///
/// | route        | tab        | sent for (phase 2)                              |
/// |--------------|------------|-------------------------------------------------|
/// | `interviews` | Interviews | invites, rounds, offers, recruiter checks and   |
/// |              |            | submissions (they live on the Interviews tab)   |
/// | `skills`     | Skills     | a badge was issued                              |
/// | `jobs`       | Jobs       | an application status changed, match digest     |
/// | `profile`    | Profile    | recruiter availability going stale               |
/// | `home`       | Home       | anything else                                   |
int tabForPushRoute(String? route) => switch (route) {
      'interviews' => RootTab.interviews,
      'skills' || 'badges' => RootTab.badges,
      'jobs' => RootTab.jobs,
      'profile' => RootTab.profile,
      _ => RootTab.home,
    };
