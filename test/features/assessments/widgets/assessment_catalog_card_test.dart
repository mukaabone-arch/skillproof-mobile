import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skillproof/features/assessments/widgets/assessment_catalog_card.dart';
import 'package:skillproof/models/assessment_catalog_entry.dart';
import 'package:skillproof/theme/app_theme.dart';

AssessmentCatalogEntry _entry({
  AssessmentCatalogState state = AssessmentCatalogState.available,
  String badgeLevel = 'L2',
  bool discussion = false,
  int relevanceCount = 0,
  DateTime? retakeAvailableAt,
}) {
  return AssessmentCatalogEntry(
    skillId: 'skill-1',
    skillName: 'RAG Systems',
    relevanceCount: relevanceCount,
    badgeLevel: badgeLevel,
    levelState: 'AVAILABLE',
    estMinutes: discussion ? 20 : 30,
    state: state,
    webPath: discussion ? '/assessments/discussion/rag-systems-l2' : '/assessments/assessment-1',
    retakeAvailableAt: retakeAvailableAt,
  );
}

/// Renders at a ~375-wide phone viewport — same convention as
/// usage_meter_test.dart / feature_strip_test.dart. Any RenderFlex overflow
/// throws in the test harness, so these passing IS the no-overflow check.
Widget _host(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
  );
}

void main() {
  testWidgets('names the level and states what it proves, code kept as secondary label', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(AssessmentCatalogCard(entry: _entry(), onTakeAssessment: () {})));

    expect(find.text('Practitioner'), findsOneWidget);
    expect(find.textContaining('Level L2 · Applies the skill independently on real work.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a timed-test entry labels itself as a test, no discussion note', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(AssessmentCatalogCard(entry: _entry(), onTakeAssessment: () {})));

    expect(find.textContaining('Timed test · 30 min'), findsOneWidget);
    expect(find.textContaining('reasoning live'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a discussion entry labels itself as a live discussion and clarifies what that means', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(AssessmentCatalogCard(entry: _entry(discussion: true), onTakeAssessment: () {})));

    expect(find.textContaining('Live discussion · 20 min'), findsOneWidget);
    expect(find.textContaining('reasoning live'), findsOneWidget);
    expect(find.textContaining('same verified badge as a timed test'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cooldown state explains why retakes are limited, not just the bare date', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(AssessmentCatalogCard(
      entry: _entry(state: AssessmentCatalogState.cooldown, retakeAvailableAt: DateTime.utc(2026, 8, 1)),
      onTakeAssessment: () {},
    )));

    expect(find.textContaining('Retakes are limited so badges stay credible to employers'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
