import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payfxglobal/widgets/logout_dialog.dart';

void main() {
  group('LogoutDialog Widget Tests', () {
    testWidgets('Displays logout confirmation dialog with Log Out and Cancel buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/welcome': (context) => const Scaffold(body: Text('Welcome Screen')),
          },
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => LogoutDialog.show(context),
                child: const Text('Show Logout'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Logout'));
      await tester.pumpAndSettle();

      expect(find.text('Do you want to\nlog out ?'), findsOneWidget);
      expect(find.text('Are you sure about to log out from the application'), findsOneWidget);
      expect(find.text('Log Out'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap Cancel to dismiss dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Do you want to\nlog out ?'), findsNothing);
    });
  });
}
