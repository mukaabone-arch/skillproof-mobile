import 'package:flutter_test/flutter_test.dart';
import 'package:skillproof/features/assessments/card_state.dart';
import 'package:skillproof/models/assessment_catalog_entry.dart';

AssessmentCatalogEntry _entry({
  required AssessmentCatalogState state,
  DateTime? retakeAvailableAt,
}) {
  return AssessmentCatalogEntry(
    skillId: 'skill-1',
    skillName: 'Model Deployment',
    relevanceCount: 4,
    badgeLevel: 'L2',
    levelState: 'AVAILABLE',
    estMinutes: 30,
    state: state,
    webPath: '/assessments/assessment-1',
    retakeAvailableAt: retakeAvailableAt,
  );
}

void main() {
  group('resolveCardDisplay', () {
    test('available: enabled "Take assessment", no meta text', () {
      final display = resolveCardDisplay(_entry(state: AssessmentCatalogState.available));

      expect(display.buttonEnabled, isTrue);
      expect(display.buttonLabel, 'Take assessment');
      expect(display.metaText, isNull);
    });

    test('in_progress: disabled, with an explanatory meta line', () {
      final display = resolveCardDisplay(_entry(state: AssessmentCatalogState.inProgress));

      expect(display.buttonEnabled, isFalse);
      expect(display.buttonLabel, 'Assessment in progress');
      expect(display.metaText, isNotNull);
    });

    test('cooldown: disabled, shows the local-time retake date, nudges Free to upgrade', () {
      final retakeAt = DateTime.utc(2026, 7, 24, 10);
      final display = resolveCardDisplay(
        _entry(state: AssessmentCatalogState.cooldown, retakeAvailableAt: retakeAt),
      );

      expect(display.buttonEnabled, isFalse);
      expect(display.metaText, contains('Retake available from'));
      expect(display.metaText, contains('Premium removes retake cooldowns entirely'));
      // The API's ISO-8601 UTC timestamp is rendered in device-local time,
      // not echoed back verbatim.
      final expectedLocal = retakeAt.toLocal();
      final expectedDate =
          '${expectedLocal.year}-${expectedLocal.month.toString().padLeft(2, '0')}-${expectedLocal.day.toString().padLeft(2, '0')}';
      expect(display.metaText, contains(expectedDate));
    });

    test('cooldown: Premium gets the date with no upgrade nudge', () {
      final retakeAt = DateTime.utc(2026, 7, 24, 10);
      final display = resolveCardDisplay(
        _entry(state: AssessmentCatalogState.cooldown, retakeAvailableAt: retakeAt),
        premium: true,
      );

      expect(display.metaText, contains('Retake available from'));
      expect(display.metaText, isNot(contains('Premium')));
    });

    test('cooldown with no retakeAvailableAt: disabled, explains the lifetime cap, nudges Free to upgrade', () {
      final display = resolveCardDisplay(_entry(state: AssessmentCatalogState.cooldown));

      expect(display.buttonEnabled, isFalse);
      expect(display.metaText, contains("used all retakes allowed"));
      expect(display.metaText, contains('Premium allows more retakes per skill'));
    });

    test('cooldown with no retakeAvailableAt: Premium still sees the cap explained, no upgrade nudge', () {
      final display = resolveCardDisplay(_entry(state: AssessmentCatalogState.cooldown), premium: true);

      expect(display.metaText, contains("used all retakes allowed"));
      expect(display.metaText, isNot(contains('Premium')));
    });
  });
}
