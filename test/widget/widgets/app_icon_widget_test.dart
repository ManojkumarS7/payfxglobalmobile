import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payfxglobal/widgets/app_icon_widget.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('AppIconWidget Tests', () {
    testWidgets('Renders PAYUNI text and custom icon painter', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const AppIconWidget(size: 200),
        ),
      );

      expect(find.text('PAYUNI'), findsOneWidget);
      expect(find.byType(CustomPaint).first, findsOneWidget);
    });
  });
}
