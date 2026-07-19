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

    test('cooldown: disabled, shows the local-time retake date', () {
      final retakeAt = DateTime.utc(2026, 7, 24, 10);
      final display = resolveCardDisplay(
        _entry(state: AssessmentCatalogState.cooldown, retakeAvailableAt: retakeAt),
      );

      expect(display.buttonEnabled, isFalse);
      expect(display.metaText, contains('Retake available from'));
      // The API's ISO-8601 UTC timestamp is rendered in device-local time,
      // not echoed back verbatim.
      final expectedLocal = retakeAt.toLocal();
      final expectedDate =
          '${expectedLocal.year}-${expectedLocal.month.toString().padLeft(2, '0')}-${expectedLocal.day.toString().padLeft(2, '0')}';
      expect(display.metaText, contains(expectedDate));
    });

    test('cooldown with no retakeAvailableAt: disabled, no meta text', () {
      final display = resolveCardDisplay(_entry(state: AssessmentCatalogState.cooldown));

      expect(display.buttonEnabled, isFalse);
      expect(display.metaText, isNull);
    });
  });
}
