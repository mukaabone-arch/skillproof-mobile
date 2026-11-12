import 'package:flutter_test/flutter_test.dart';
import 'package:myambii/core/client_country.dart';

void main() {
  test('an Indian clock means India, whatever the locale', () {
    expect(clientCountry(utcOffset: const Duration(hours: 5, minutes: 30), localeName: 'en_US'), 'IN');
  });

  test("elsewhere the locale's region is used, or ZZ", () {
    expect(clientCountry(utcOffset: const Duration(hours: 4), localeName: 'en_AE'), 'AE');
    expect(clientCountry(utcOffset: Duration.zero, localeName: 'en-GB'), 'GB');
    expect(clientCountry(utcOffset: const Duration(hours: -5), localeName: 'en'), 'ZZ');
  });
}
