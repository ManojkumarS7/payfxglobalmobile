// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.


import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payfxglobal/features/auth/view/login_screen.dart';

void main() {
  group('PayFX Global Login Screen Tests', () {

    testWidgets('Login screen displays correctly',
            (WidgetTester tester) async {

          await tester.pumpWidget(
            const MaterialApp(
              home: LoginScreen(),
            ),
          );

          await tester.pumpAndSettle();

          expect(find.text('Welcome Back'), findsOneWidget);
          expect(find.text('Send Money Anywhere, Anytime'), findsOneWidget);
          expect(find.text('Sign In'), findsOneWidget);
          expect(find.text('Forgot Password?'), findsOneWidget);

        });

    testWidgets('Empty email and password show validation errors',
            (WidgetTester tester) async {

          await tester.pumpWidget(
            const MaterialApp(
              home: LoginScreen(),
            ),
          );

          await tester.pumpAndSettle();

          final signInButton = find.text('Sign In');

          await tester.ensureVisible(signInButton);
          await tester.tap(signInButton);

          await tester.pumpAndSettle();

          expect(
            find.text('This field is required'),
            findsNWidgets(2),
          );

        });

  });
}
