
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payfxglobal/widgets/custom_button.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('AppPrimaryButton Tests', () {
    testWidgets('Displays button title', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          AppPrimaryButton(
            title: 'Login',
            onPressed: () {},
          ),
        ),
      );

      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('Calls onPressed when tapped', (tester) async {
      bool isPressed = false;

      await tester.pumpWidget(
        createTestWidget(
          AppPrimaryButton(
            title: 'Continue',
            onPressed: () {
              isPressed = true;
            },
          ),
        ),
      );

      await tester.tap(find.text('Continue'));
      expect(isPressed, true);
    });

    testWidgets('Disables button while loading', (tester) async {
      bool isPressed = false;

      await tester.pumpWidget(
        createTestWidget(
          AppPrimaryButton(
            title: 'Loading',
            loading: true,
            onPressed: () {
              isPressed = true;
            },
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );

      expect(button.onPressed, isNull);

      await tester.tap(find.byType(ElevatedButton));
      expect(isPressed, false);
    });
  });

  group('CustomButton Tests', () {
    testWidgets('Displays button text', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          CustomButton(
            text: 'Submit',
            onPressed: () {},
          ),
        ),
      );

      expect(find.text('Submit'), findsOneWidget);
    });

    testWidgets('Calls onPressed when tapped', (tester) async {
      bool isPressed = false;

      await tester.pumpWidget(
        createTestWidget(
          CustomButton(
            text: 'Submit',
            onPressed: () {
              isPressed = true;
            },
          ),
        ),
      );

      await tester.tap(find.text('Submit'));
      expect(isPressed, true);
    });

    testWidgets('Does not respond when disabled', (tester) async {
      bool isPressed = false;

      await tester.pumpWidget(
        createTestWidget(
          CustomButton(
            text: 'Disabled',
            isEnabled: false,
            onPressed: () {
              isPressed = true;
            },
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );

      expect(button.onPressed, isNull);

      await tester.tap(find.text('Disabled'));
      expect(isPressed, false);
    });

    testWidgets('Disables button when callback is null', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const CustomButton(
            text: 'No Action',
            onPressed: null,
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );

      expect(button.onPressed, isNull);
    });

    testWidgets('Shows loading indicator', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          CustomButton(
            text: 'Loading',
            isLoading: true,
            onPressed: () {},
          ),
        ),
      );

      expect(
        find.byType(CircularProgressIndicator),
        findsOneWidget,
      );

      expect(find.text('Loading'), findsNothing);
    });

    testWidgets('Displays optional icon', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          CustomButton(
            text: 'Add Recipient',
            icon: Icons.person_add,
            onPressed: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.person_add), findsOneWidget);
      expect(find.text('Add Recipient'), findsOneWidget);
    });

    testWidgets('Supports custom height and width', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          CustomButton(
            text: 'Custom Size',
            width: 200,
            height: 60,
            onPressed: () {},
          ),
        ),
      );

      final size = tester.getSize(find.byType(CustomButton));

      expect(size.width, 200);
      expect(size.height, 60);
    });

    testWidgets('Renders with gradient decoration', (tester) async {
      const gradient = LinearGradient(
        colors: [Colors.blue, Colors.green],
      );

      await tester.pumpWidget(
        createTestWidget(
          CustomButton(
            text: 'Gradient',
            gradient: gradient,
            onPressed: () {},
          ),
        ),
      );

      expect(find.text('Gradient'), findsOneWidget);

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.byType(ElevatedButton),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration;

      expect(decoration.gradient, same(gradient));
    });
  });

  group('OutlinedCustomButton Tests', () {
    testWidgets('Displays outlined button text', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          OutlinedCustomButton(
            text: 'Cancel',
            onPressed: () {},
          ),
        ),
      );

      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Calls onPressed when tapped', (tester) async {
      bool isPressed = false;

      await tester.pumpWidget(
        createTestWidget(
          OutlinedCustomButton(
            text: 'Cancel',
            onPressed: () {
              isPressed = true;
            },
          ),
        ),
      );

      await tester.tap(find.text('Cancel'));
      expect(isPressed, true);
    });

    testWidgets('Supports disabled state', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          OutlinedCustomButton(
            text: 'Disabled',
            isEnabled: false,
            onPressed: () {},
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );

      expect(button.onPressed, isNull);
    });
  });

  group('IconCustomButton Tests', () {
    testWidgets('Displays icon and tooltip', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          IconCustomButton(
            icon: Icons.edit,
            tooltip: 'Edit Profile',
            onPressed: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byTooltip('Edit Profile'), findsOneWidget);
    });

    testWidgets('Calls onPressed when tapped', (tester) async {
      bool isPressed = false;

      await tester.pumpWidget(
        createTestWidget(
          IconCustomButton(
            icon: Icons.delete,
            onPressed: () {
              isPressed = true;
            },
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.delete));
      expect(isPressed, true);
    });

    testWidgets('Supports custom size', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          IconCustomButton(
            icon: Icons.settings,
            size: 60,
            onPressed: () {},
          ),
        ),
      );

      final size = tester.getSize(find.byType(IconCustomButton));

      expect(size.width, 60);
      expect(size.height, 60);
    });
  });
}
