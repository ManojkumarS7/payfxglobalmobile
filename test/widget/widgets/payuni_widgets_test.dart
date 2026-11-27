import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payfxglobal/widgets/payuni_widgets.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('PayUni Widgets Tests', () {
    testWidgets('PayUniLoadingWidget renders indicator and message', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const PayUniLoadingWidget(
            size: 60,
            message: 'Loading transaction details...',
          ),
        ),
      );

      expect(find.byType(PayUniLoadingWidget), findsOneWidget);
      expect(find.text('Loading transaction details...'), findsOneWidget);
      expect(find.byType(CustomPaint).first, findsOneWidget);
    });

    testWidgets('PayUniLogo renders logo text and icon painter', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const PayUniLogo(
            width: 320,
            height: 60,
          ),
        ),
      );

      expect(find.text('PayFX Global'), findsOneWidget);
      expect(find.byType(CustomPaint).first, findsOneWidget);
    });
  });
}
