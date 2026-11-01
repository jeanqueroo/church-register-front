import 'package:church_register/core/utils/birthday_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BirthdayDate.isToday', () {
    test('coincide con fecha local de hoy', () {
      final today = DateTime(2026, 6, 5);
      final birth = DateTime(1990, 6, 5);

      expect(BirthdayDate.isToday(birth, today), isTrue);
    });

    test('no coincide con otro día', () {
      final today = DateTime(2026, 6, 5);
      final birth = DateTime(1990, 6, 6);

      expect(BirthdayDate.isToday(birth, today), isFalse);
    });

    test('acepta medianoche UTC como día civil', () {
      final today = DateTime(2026, 6, 5);
      final birthUtc = DateTime.utc(1990, 6, 5);

      expect(BirthdayDate.isToday(birthUtc, today), isTrue);
    });
  });

  group('BirthdayDate.normalize', () {
    test('elimina componente de hora en local', () {
      final date = DateTime(1990, 3, 15, 14, 30);
      final normalized = BirthdayDate.normalize(date);

      expect(normalized, DateTime(1990, 3, 15));
    });
  });
}
