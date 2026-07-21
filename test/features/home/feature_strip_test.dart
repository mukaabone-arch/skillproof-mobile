import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skillproof/features/home/widgets/feature_strip.dart';
import 'package:skillproof/theme/app_theme.dart';

/// Renders the strip at a ~375-wide phone viewport. Any RenderFlex overflow
/// throws in the test harness, so these passing IS the no-overflow check.
Widget _host({bool disableAnimations = false}) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: MediaQuery(
      data: MediaQueryData(size: const Size(375, 667), disableAnimations: disableAnimations),
      child: const Scaffold(body: Padding(padding: EdgeInsets.all(16), child: FeatureStrip())),
    ),
  );
}

void main() {
  testWidgets('renders five stages without overflow at 375 width and animates', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host());

    for (final label in ['Verify skills', 'Earn badges', 'Match roles', 'Interview', 'Get hired']) {
      expect(find.text(label), findsOneWidget);
    }

    // Step through more than one full 7.5s loop — every stage window and the
    // loop-reset fade all render without layout errors.
    for (var i = 0; i < 11; i++) {
      await tester.pump(const Duration(milliseconds: 750));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion shows the static journey-complete state', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(disableAnimations: true));
    await tester.pump(const Duration(seconds: 1));

    // No running animation: nothing schedules further frames.
    expect(tester.hasRunningAnimations, isFalse);
    expect(find.text('Get hired'), findsOneWidget);
  });
}
