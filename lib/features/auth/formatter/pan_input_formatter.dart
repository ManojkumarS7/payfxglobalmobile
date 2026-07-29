import 'package:flutter/services.dart';

class PanInputFormatter extends TextInputFormatter {

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {

    final text = newValue.text.toUpperCase();

    final buffer = StringBuffer();

    int selectionIndex =
        newValue.selection.end;

    int bufferLength = 0;

    for (int i = 0;
    i < text.length && bufferLength < 10;
    i++) {

      final char = text[i];

      if (bufferLength < 5) {

        if (RegExp(r'[A-Z]')
            .hasMatch(char)) {

          buffer.write(char);
          bufferLength++;

        } else if (i < selectionIndex) {

          selectionIndex--;
        }

      } else if (bufferLength < 9) {

        if (RegExp(r'[0-9]')
            .hasMatch(char)) {

          buffer.write(char);
          bufferLength++;

        } else if (i < selectionIndex) {

          selectionIndex--;
        }

      } else {

        if (RegExp(r'[A-Z]')
            .hasMatch(char)) {

          buffer.write(char);
          bufferLength++;

        } else if (i < selectionIndex) {

          selectionIndex--;
        }
      }
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(
        offset: selectionIndex,
      ),
    );
  }
}