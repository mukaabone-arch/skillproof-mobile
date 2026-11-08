import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myambii/features/help/help_assistant_screen.dart';
import 'package:myambii/features/help/help_repository.dart';
import 'package:myambii/theme/app_theme.dart';

class _NoConsent extends HelpConsentStore {
  @override
  Future<bool> hasConsented() async => false;
}

void main() {
  testWidgets('openHelpAssistant pushes the Ask MyAmbii screen', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [helpConsentStoreProvider.overrideWithValue(_NoConsent())],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: Builder(
          builder: (context) => Scaffold(
            appBar: AppBar(actions: [
              IconButton(tooltip: 'Help', icon: const Icon(Icons.help_outline), onPressed: () => openHelpAssistant(context)),
            ]),
          ),
        ),
      ),
    ));

    await tester.tap(find.byTooltip('Help'));
    await tester.pumpAndSettle();

    expect(find.text('Ask MyAmbii'), findsOneWidget);
    expect(find.text('Before you start'), findsOneWidget);
  });
}
