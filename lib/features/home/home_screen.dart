import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_colors.dart';
import '../auth/auth_controller.dart';
import '../badges/badges_controller.dart';
import '../certifications/certifications_controller.dart';
import '../entitlements/entitlements_controller.dart';
import '../jobs/applications_controller.dart';
import '../jobs/matched_controller.dart';
import '../profile/profile_controller.dart';
import 'widgets/feature_strip.dart';
import 'widgets/hero_section.dart';
import 'widgets/status_cards.dart';

/// Candidate dashboard hub — orient, show status, prompt the next action.
/// Mirrors apps/web/components/Dashboard.tsx's purpose, phone-native:
/// every section loads and fails independently (see HeroSection /
/// StatusCardsRow) rather than blocking the whole screen behind the
/// slowest of five endpoints, which is what the web version does. Reuses
/// the existing profile/badges/certifications/jobs controllers
/// throughout — this screen has no repository of its own. The matched-jobs
/// load below is NOT dead despite no match list rendering here anymore:
/// HeroSection's co-pilot reads matchedControllerProvider for its
/// best-match/recurring-gap suggestions (the list itself lives on the
/// Jobs tab's Matched view).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Not rendered from directly on this screen — watched here purely so
    // entitlements are fetched immediately at app start, since Home is
    // always the first tab RootScreen's IndexedStack builds.
    ref.watch(entitlementsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SkillProof'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
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
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.space4),
          children: const [
            HeroSection(),
            SizedBox(height: AppSpacing.space5),
            StatusCardsRow(),
            SizedBox(height: AppSpacing.space7),
            // Footer flourish, mirroring web Dashboard's placement at the
            // very bottom of the page (web puts it under the resume link;
            // this screen has no resume link, so it simply closes the page).
            FeatureStrip(),
          ],
        ),
      ),
    );
  }
}
