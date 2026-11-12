import 'package:flutter_test/flutter_test.dart';
import 'package:myambii/models/user.dart';

void main() {
  group('MyambiiUser.isVerified', () {
    test('needs phone and email when a phone is required (India, or not said)', () {
      final user = MyambiiUser.fromJson({'id': 'u1', 'role': 'CANDIDATE', 'email': 'a@b.co'});
      expect(user.phoneRequired, isTrue);
      expect(user.isVerified, isFalse);
    });

    test('needs only an email outside India', () {
      final user = MyambiiUser.fromJson({'id': 'u1', 'role': 'CANDIDATE', 'email': 'a@b.co', 'phoneRequired': false});
      expect(user.isVerified, isTrue);
    });

    test('still needs the email outside India', () {
      final user = MyambiiUser.fromJson({'id': 'u1', 'role': 'CANDIDATE', 'phoneRequired': false});
      expect(user.isVerified, isFalse);
    });
  });
}
