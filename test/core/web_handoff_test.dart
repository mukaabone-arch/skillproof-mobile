import 'package:flutter_test/flutter_test.dart';
import 'package:myambii/config/api_config.dart';
import 'package:myambii/core/web_handoff.dart';

void main() {
  group('openWebAuthenticated', () {
    test('opens the handoff URL with the code and the URL-encoded path', () async {
      final opened = <String>[];
      await openWebAuthenticated(
        '/assessments/discussion/session/abc',
        () async => 'the-code',
        openBrowser: (url) async => opened.add(url),
      );

      expect(opened, [
        '${ApiConfig.webBaseUrl}/auth/handoff?code=the-code&next=%2Fassessments%2Fdiscussion%2Fsession%2Fabc',
      ]);
    });

    test('a failed code request still opens the browser, plainly, rather than leaving a dead button', () async {
      final opened = <String>[];
      await openWebAuthenticated(
        '/resume',
        () async => throw Exception('network error'),
        openBrowser: (url) async => opened.add(url),
      );

      expect(opened, ['${ApiConfig.webBaseUrl}/resume']);
    });
  });
}
