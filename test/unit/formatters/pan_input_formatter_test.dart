
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payfxglobal/features/auth/formatter/pan_input_formatter.dart';

void main() {
  late PanInputFormatter formatter;

  setUp(() {
    formatter = PanInputFormatter();
  });

  TextEditingValue format(String input) {
    return formatter.formatEditUpdate(
      const TextEditingValue(text: ''),
      TextEditingValue(
        text: input,
        selection: TextSelection.collapsed(
          offset: input.length,
        ),
      ),
    );
  }

  group('PAN Input Formatter Unit Tests', () {

    test('Converts lowercase input to uppercase', () {
      final result = format('abcde1234f');

      expect(result.text, 'ABCDE1234F');
    });

    test('Accepts a valid 10-character PAN format', () {
      final result = format('ABCDE1234F');

      expect(result.text, 'ABCDE1234F');
      expect(result.text.length, 10);
    });

    test('Accepts alphabetic characters in first five positions', () {
      final result = format('ABCDE1234F');

      expect(result.text.substring(0, 5), 'ABCDE');
    });

    test('Accepts numeric characters in positions six to nine', () {
      final result = format('ABCDE1234F');

      expect(result.text.substring(5, 9), '1234');
    });

    test('Accepts an alphabetic character in the tenth position', () {
      final result = format('ABCDE1234F');

      expect(result.text[9], 'F');
    });

    test('Does not allow more than 10 characters', () {
      final result = format('ABCDE1234FXYZ');

      expect(result.text, 'ABCDE1234F');
      expect(result.text.length, 10);
    });

    test('Removes invalid characters based on accepted positions', () {
      final result = format('AB@DE123#F');

      expect(result.text, 'ABDEF');
    });

    test('Handles empty input', () {
      final result = format('');

      expect(result.text, '');
    });

    test('Rejects numbers in the first five positions', () {
      final result = format('12345ABCDE');

      expect(result.text, 'ABCDE');
    });

    test('Rejects letters in numeric positions', () {
      final result = format('ABCDEABCD1');

      expect(result.text, 'ABCDE1');
    });
  });
}
