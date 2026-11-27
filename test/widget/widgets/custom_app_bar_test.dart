import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payfxglobal/widgets/custom_app_bar.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        appBar: child as PreferredSizeWidget,
        body: const Center(child: Text('Content')),
      ),
    );
  }

  group('AppPrimaryAppBar Widget Tests', () {
    testWidgets('Renders title correctly', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const AppPrimaryAppBar(
            title: 'Dashboard Header',
          ),
        ),
      );

      expect(find.text('Dashboard Header'), findsOneWidget);
    });

    testWidgets('Shows back button by default and triggers back callback', (tester) async {
      bool backTapped = false;

      await tester.pumpWidget(
        createTestWidget(
          AppPrimaryAppBar(
            title: 'Back Test',
            onBack: () {
              backTapped = true;
            },
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      expect(backTapped, true);
    });

    testWidgets('Hides back button when showBackButton is false', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const AppPrimaryAppBar(
            title: 'No Back',
            showBackButton: false,
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('Renders actions passed to app bar', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          AppPrimaryAppBar(
            title: 'With Actions',
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {},
              ),
            ],
          ),
        ),
      );

      expect(find.byIcon(Icons.notifications), findsOneWidget);
    });

    testWidgets('Applies custom background and text color', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const AppPrimaryAppBar(
            title: 'Custom Colored',
            backgroundColor: Colors.blue,
            textColor: Colors.white,
          ),
        ),
      );

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, Colors.blue);

      final text = tester.widget<Text>(find.text('Custom Colored'));
      expect(text.style?.color, Colors.white);
    });
  });
}
