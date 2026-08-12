import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myambii/theme/app_theme.dart';
import 'package:myambii/widgets/app_button.dart';

/// Renders at a ~375-wide phone viewport. Any RenderFlex overflow throws in
/// the test harness, so these passing IS the no-overflow check — same
/// convention as usage_meter_test.dart / feature_strip_test.dart.
Widget _host(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
  );
}

void main() {
  testWidgets('an icon+label button with a long label ellipsizes instead of overflowing at 375 width', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // Same shape as login_screen.dart's Google button: expand: true (the
    // width-constraining case the bug depended on) with a long label and an
    // icon, which is what used to overflow here before Flexible was added.
    await tester.pumpWidget(_host(AppButton(
      label: 'Sign in with Google',
      variant: AppButtonVariant.secondary,
      icon: const Icon(Icons.g_mobiledata),
      expand: true,
      onPressed: () {},
    )));

    expect(find.text('Sign in with Google'), findsOneWidget);
    final text = tester.widget<Text>(find.text('Sign in with Google'));
    expect(text.overflow, TextOverflow.ellipsis);
    expect(text.maxLines, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an icon+label button without expand still renders at its natural width, unaffected', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(AppButton(
      label: 'Retry',
      icon: const Icon(Icons.refresh),
      onPressed: () {},
    )));

    expect(find.text('Retry'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
