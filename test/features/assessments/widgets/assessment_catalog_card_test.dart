import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myambii/features/assessments/widgets/assessment_catalog_card.dart';
import 'package:myambii/models/assessment_catalog_entry.dart';
import 'package:myambii/theme/app_theme.dart';

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

  testWidgets(
    'profile not ready: disables Take assessment, shows what is missing with a Go to Profile action, no overflow at 375',
    (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var completedProfileTapped = false;
      var tookAssessmentTapped = false;

      await tester.pumpWidget(_host(AssessmentCatalogCard(
        entry: _entry(),
        onTakeAssessment: () => tookAssessmentTapped = true,
        profileReady: false,
        profileGateMessage: 'Add a headline or your years of experience to start earning verified badges.',
        onCompleteProfile: () => completedProfileTapped = true,
      )));

      expect(
        find.text('Add a headline or your years of experience to start earning verified badges.'),
        findsOneWidget,
      );
      expect(find.text('Go to Profile'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // The disabled AppButton still renders "Take assessment" (the reason
      // — the ActionableNotice above it — is what changes, not the button's
      // own label) but tapping it must not fire onTakeAssessment.
      await tester.tap(find.widgetWithText(FilledButton, 'Take assessment'));
      await tester.pump();
      expect(tookAssessmentTapped, isFalse);

      await tester.tap(find.text('Go to Profile'));
      await tester.pump();
      expect(completedProfileTapped, isTrue);
    },
  );

  testWidgets('profile not ready but this entry is already in cooldown: the cooldown reason wins, no gate notice shown', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(AssessmentCatalogCard(
      entry: _entry(state: AssessmentCatalogState.cooldown, retakeAvailableAt: DateTime.utc(2026, 8, 1)),
      onTakeAssessment: () {},
      profileReady: false,
      profileGateMessage: 'Add your name to start earning verified badges.',
    )));

    expect(find.textContaining('Retakes are limited so badges stay credible to employers'), findsOneWidget);
    expect(find.text('Go to Profile'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
