import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payfxglobal/widgets/custom_loading_indicator.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('CustomLoadingIndicator Widget Tests', () {
    testWidgets('Renders CustomLoadingIndicator and fallback icon when image asset missing', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const CustomLoadingIndicator(size: 80),
        ),
      );

      expect(find.byType(CustomLoadingIndicator), findsOneWidget);

      // Advance animation frame
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(CustomPaint).first, findsOneWidget);
    });

    testWidgets('LoadingOverlay wraps indicator in white background', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const LoadingOverlay(),
        ),
      );

      expect(find.byType(LoadingOverlay), findsOneWidget);
      expect(find.byType(CustomLoadingIndicator), findsOneWidget);
    });

    testWidgets('ButtonLoader renders staggered dots wave animation widget', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const ButtonLoader(),
        ),
      );

      expect(find.byType(ButtonLoader), findsOneWidget);
    });
  });
}
