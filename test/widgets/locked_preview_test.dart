import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skillproof/theme/app_theme.dart';
import 'package:skillproof/widgets/locked_preview.dart';

Widget _host(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
  );
}

void main() {
  testWidgets('shows the real teaser, the overlay label, and the preview content at 375 width', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(const LockedPreview(
      teaser: '4 employers have viewed your profile.',
      overlayLabel: 'Premium unlocks who',
      child: Text('Employer'),
    )));

    // The teaser is always real data, never a hardcoded marketing line.
    expect(find.text('4 employers have viewed your profile.'), findsOneWidget);
    expect(find.text('Premium unlocks who'), findsOneWidget);
    // The preview content is visible-but-locked, not absent — it's in the
    // tree (blurred/dimmed via ImageFiltered+Opacity, not removed) and
    // non-interactive (wrapped in IgnorePointer, alongside whatever
    // ambient IgnorePointer widgets MaterialApp/Scaffold itself uses).
    expect(find.text('Employer'), findsOneWidget);
    expect(
      find.ancestor(of: find.text('Employer'), matching: find.byType(IgnorePointer)),
      findsWidgets,
    );
    expect(find.byType(ImageFiltered), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
