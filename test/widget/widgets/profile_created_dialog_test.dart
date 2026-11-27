import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payfxglobal/widgets/profile_created_dialog.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return MaterialApp(
      routes: {
        '/dashboard': (context) => const Scaffold(body: Text('Dashboard')),
      },
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('ProfileCreatedDialog Widget Tests', () {
    testWidgets('Renders success dialog elements and Go to Home action', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const ProfileCreatedDialog(
            userId: 1,
            userData: {'user_id': 1, 'full_name': 'Test User'},
          ),
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Profile successfully created.'), findsOneWidget);
      expect(find.text('Your profile is ready. You can now start using PayFX Global.'), findsOneWidget);
      expect(find.text('Go to Home'), findsOneWidget);

      await tester.tap(find.text('Go to Home'));
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
    });
  });
}
