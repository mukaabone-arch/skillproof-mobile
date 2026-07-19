import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:skillproof/core/api_client.dart';
import 'package:skillproof/features/assessments/assessments_controller.dart';
import 'package:skillproof/features/assessments/assessments_repository.dart';
import 'package:skillproof/models/assessment_catalog_entry.dart';

AssessmentCatalogEntry _entry(String skillId) => AssessmentCatalogEntry(
      skillId: skillId,
      skillName: 'Skill $skillId',
      relevanceCount: 1,
      badgeLevel: 'L1',
      estMinutes: 10,
      state: AssessmentCatalogState.available,
      webPath: '/assessments/$skillId',
    );

/// [AssessmentsController.takeAssessment] never calls the repository, so a
/// real (never-invoked) one is fine here — no network/secure-storage calls
/// happen unless catalogSummary() is actually called, which none of these
/// tests do.
AssessmentsRepository _unusedRepository() => AssessmentsRepository(apiClient: ApiClient());

void main() {
  group('AssessmentsController.takeAssessment double-launch guard', () {
    test('a rapid double-tap on the same skill only launches once', () async {
      final launched = <String>[];
      final completer = Completer<void>();
      final controller = AssessmentsController(
        _unusedRepository(),
        launcher: (url) async {
          launched.add(url);
          await completer.future;
        },
      );

      final first = controller.takeAssessment(_entry('skill-1'));
      final second = controller.takeAssessment(_entry('skill-1')); // fired before the first resolves

      completer.complete();
      await first;
      await second;

      expect(launched, hasLength(1));
    });

    test('launching a different skill is not blocked by one already in flight', () async {
      final launched = <String>[];
      final completer = Completer<void>();
      final controller = AssessmentsController(
        _unusedRepository(),
        launcher: (url) async {
          launched.add(url);
          await completer.future;
        },
      );

      final first = controller.takeAssessment(_entry('skill-1'));
      final second = controller.takeAssessment(_entry('skill-2'));

      completer.complete();
      await first;
      await second;

      expect(launched, hasLength(2));
    });

    test('the same skill can be launched again once the previous launch finished', () async {
      final launched = <String>[];
      final controller = AssessmentsController(
        _unusedRepository(),
        launcher: (url) async => launched.add(url),
      );

      await controller.takeAssessment(_entry('skill-1'));
      await controller.takeAssessment(_entry('skill-1'));

      expect(launched, hasLength(2));
    });
  });
}
