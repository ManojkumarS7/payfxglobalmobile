import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payfxglobal/widgets/app_intro_loader.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  group('AppIntroLoader Widget Tests', () {
    testWidgets('Renders AppIntroLoader screen with public earth icon and currency icons', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const AppIntroLoader(),
        ),
      );

      expect(find.byType(AppIntroLoader), findsOneWidget);
      expect(find.byIcon(Icons.public), findsOneWidget);
      expect(find.byIcon(Icons.currency_rupee), findsOneWidget);
      expect(find.byIcon(Icons.attach_money), findsOneWidget);
    });
  });
}
