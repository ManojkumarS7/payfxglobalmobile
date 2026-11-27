import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payfxglobal/widgets/custom_app_drawer.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        drawer: const CustomAppDrawer(),
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            child: const Text('Open Drawer'),
          ),
        ),
      ),
    );
  }

  group('CustomAppDrawer Widget Tests', () {
    testWidgets('Opens drawer and displays menu items', (tester) async {
      await tester.pumpWidget(createTestWidget(const CustomAppDrawer()));

      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      expect(find.text('Menu'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);
    });

    testWidgets('Displays icons for menu items', (tester) async {
      await tester.pumpWidget(createTestWidget(const CustomAppDrawer()));

      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });
  });
}
