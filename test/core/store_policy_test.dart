import 'package:flutter_test/flutter_test.dart';
import 'package:myambii/core/store_policy.dart';
import 'package:myambii/features/assessments/card_state.dart';
import 'package:myambii/models/assessment_catalog_entry.dart';

/// iOS must never name or preview a paid plan (App Store 3.1.1 / 3.1.3);
/// Android keeps the informational mentions. Both forced via the override
/// so this runs the same on any host.
void main() {
  tearDown(() => debugMentionPaidPlansOverride = null);

  AssessmentCatalogEntry cooldown({DateTime? at}) => AssessmentCatalogEntry(
        skillId: 's1',
        skillName: 'RAG Systems',
        relevanceCount: 4,
        badgeLevel: 'L1',
        levelState: 'AVAILABLE',
        estMinutes: 30,
        state: AssessmentCatalogState.cooldown,
        webPath: '/assessments/a1',
        retakeAvailableAt: at,
      );

  test('iOS: retake messages state the rule without naming Premium', () {
    debugMentionPaidPlansOverride = false;
    final withDate = resolveCardDisplay(cooldown(at: DateTime.utc(2026, 12, 1)));
    final capped = resolveCardDisplay(cooldown());
    expect(withDate.metaText, contains('try again'));
    expect(withDate.metaText, isNot(contains('Premium')));
    expect(capped.metaText, contains('retakes'));
    expect(capped.metaText, isNot(contains('Premium')));
  });

  test('Android: the same messages keep the Premium mention', () {
    debugMentionPaidPlansOverride = true;
    expect(resolveCardDisplay(cooldown()).metaText, contains('Premium'));
  });
}
