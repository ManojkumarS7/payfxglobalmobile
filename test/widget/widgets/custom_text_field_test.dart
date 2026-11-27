import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payfxglobal/widgets/custom_text_field.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: child,
        ),
      ),
    );
  }

  group('CustomTextField Widget Tests', () {
    testWidgets('Renders label, hint text, and prefix icon', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const CustomTextField(
            label: 'Email Address',
            hintText: 'enter@example.com',
            prefixIcon: Icons.email,
          ),
        ),
      );

      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('enter@example.com'), findsOneWidget);
      expect(find.byIcon(Icons.email), findsOneWidget);
    });

    testWidgets('Accepts input and triggers onChanged callback', (tester) async {
      String typedText = '';

      await tester.pumpWidget(
        createTestWidget(
          CustomTextField(
            hintText: 'Type here',
            onChanged: (val) {
              typedText = val;
            },
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Hello World');
      expect(typedText, 'Hello World');
    });

    testWidgets('Displays validation error message when invalid', (tester) async {
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: Column(
                children: [
                  CustomTextField(
                    hintText: 'Enter text',
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Field cannot be empty';
                      }
                      return null;
                    },
                  ),
                  ElevatedButton(
                    onPressed: () => formKey.currentState!.validate(),
                    child: const Text('Validate'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Validate'));
      await tester.pumpAndSettle();

      expect(find.text('Field cannot be empty'), findsOneWidget);
    });
  });

  group('PasswordTextField Widget Tests', () {
    testWidgets('Obscures password by default and toggles visibility on icon tap', (tester) async {
      final controller = TextEditingController(text: 'Secret123!');

      await tester.pumpWidget(
        createTestWidget(
          PasswordTextField(
            controller: controller,
            label: 'Password',
            hintText: 'Enter password',
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, true);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pumpAndSettle();

      final updatedTextField = tester.widget<TextField>(find.byType(TextField));
      expect(updatedTextField.obscureText, false);
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });
  });

  group('SearchTextField Widget Tests', () {
    testWidgets('Renders search icon and clears controller on clear icon tap', (tester) async {
      final controller = TextEditingController(text: 'Query');
      bool clearTapped = false;

      await tester.pumpWidget(
        createTestWidget(
          SearchTextField(
            controller: controller,
            hintText: 'Search items...',
            onClear: () {
              clearTapped = true;
            },
          ),
        ),
      );

      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.clear), findsOneWidget);

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(controller.text, '');
      expect(clearTapped, true);
    });
  });

  group('AmountTextField Widget Tests', () {
    testWidgets('Renders amount text field with dollar icon', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const AmountTextField(
            label: 'Send Amount',
            currency: 'USD',
          ),
        ),
      );

      expect(find.text('Send Amount'), findsOneWidget);
      expect(find.byIcon(Icons.attach_money), findsOneWidget);
      expect(find.text('0.00'), findsOneWidget);
    });
  });

  group('AppTextField Widget Tests', () {
    testWidgets('Renders label and input text', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        createTestWidget(
          AppTextField(
            controller: controller,
            labelText: 'Full Name',
            hintText: 'Enter full name',
          ),
        ),
      );

      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Enter full name'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'John Doe');
      expect(controller.text, 'John Doe');
    });
  });
}
