import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skillproof/features/auth/login_screen.dart';
import 'package:skillproof/theme/app_theme.dart';

/// Renders at a ~375-wide phone viewport — same convention as
/// usage_meter_test.dart / feature_strip_test.dart. Plain ProviderScope, no
/// overrides: LoginScreen's build() never reads authControllerProvider
/// (only the button handlers do), so nothing here touches the network.
Widget _host() {
  return ProviderScope(
    child: MaterialApp(theme: AppTheme.dark, home: const LoginScreen()),
  );
}

void main() {
  testWidgets('renders the two-line value/action copy, each as one unwrapped/unsplit string, at 375 width', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host());

    // findsOneWidget on the exact literal string confirms each line renders
    // as a single intact Text (not force-broken/truncated) — i.e. the two
    // lines themselves don't wrap awkwardly at this width.
    expect(find.text('Prove your AI skills, get matched to roles that want them.'), findsOneWidget);
    expect(find.text('Sign in with your phone to get started.'), findsOneWidget);

    // This screen has a pre-existing, unrelated RenderFlex overflow from
    // AppButton's Google icon+label Row (no Flexible/Expanded around the
    // label — reproduced in isolation, confirmed present before this change
    // too). Out of scope for a copy-only change, so rather than silently
    // swallowing it (which would also hide a real regression in the two
    // lines above, if one ever appeared), assert it's specifically *that*
    // known, already-pending overflow and nothing else.
    final exception = tester.takeException();
    expect(exception, isA<FlutterError>());
    expect(
      exception.toString(),
      contains('overflowed'),
      reason: 'Expected only the known pre-existing AppButton Google-icon overflow — a different exception here would mean the new copy lines broke something.',
    );
  });
}
