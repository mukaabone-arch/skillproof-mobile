import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skillproof/theme/app_theme.dart';
import 'package:skillproof/widgets/usage_meter.dart';

/// Renders at a ~375-wide phone viewport. Any RenderFlex overflow throws in
/// the test harness, so these passing IS the no-overflow check — same
/// convention as feature_strip_test.dart.
Widget _host(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
  );
}

void main() {
  testWidgets('shows remaining count and reset date at 375 width', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(UsageMeter(
      label: 'job applications',
      used: 4,
      limit: 10,
      resetsAt: DateTime.utc(2026, 8, 1),
    )));

    expect(find.textContaining('6 of 10 job applications left this month'), findsOneWidget);
    expect(find.textContaining('Resets Aug 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders nothing on an unlimited plan (limit: null)', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(UsageMeter(
      label: 'job applications',
      used: 4,
      limit: null,
      resetsAt: DateTime.utc(2026, 8, 1),
    )));

    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('at zero remaining, still renders (warning tone, not hidden)', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(UsageMeter(
      label: 'assessment starts',
      used: 2,
      limit: 2,
      resetsAt: DateTime.utc(2026, 8, 1),
    )));

    expect(find.textContaining('0 of 2 assessment starts left this month'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
