import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skillproof/features/badges/widgets/badge_card.dart';
import 'package:skillproof/models/badge.dart';
import 'package:skillproof/theme/app_theme.dart';

VerifiedBadge _badge({required BadgeVerificationMethod verifiedBy}) {
  return VerifiedBadge(
    skillClaimId: 'claim-1',
    skillName: 'RAG Systems',
    level: 'L2',
    verifyHash: 'hash-1',
    issuedAt: DateTime.utc(2026, 7, 1),
    verifiedBy: verifiedBy,
    attemptNumber: 1,
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
  testWidgets('names the level and states what it proves, code kept as a secondary pill label', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(BadgeCard(badge: _badge(verifiedBy: BadgeVerificationMethod.test), onTap: () {})));

    expect(find.text('Practitioner'), findsOneWidget);
    expect(find.textContaining('Level L2 · Applies the skill independently on real work.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('test-verified badge names the verifier and that employers can independently confirm it', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(BadgeCard(badge: _badge(verifiedBy: BadgeVerificationMethod.test), onTap: () {})));

    expect(
      find.textContaining('Verified by an automated test — employers can independently confirm it.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('discussion-verified badge names the verifier and that employers can independently confirm it',
      (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _host(BadgeCard(badge: _badge(verifiedBy: BadgeVerificationMethod.discussion), onTap: () {})),
    );

    expect(
      find.textContaining('Verified by a live discussion review — employers can independently confirm it.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
