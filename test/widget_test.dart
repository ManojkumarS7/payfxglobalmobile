// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:payfxglobal/main.dart';

void main() {
  testWidgets('PayUni app starts with login screen', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PayUniApp());

    // Verify that our app starts with the login screen.
    expect(find.text('PayUni'), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);

    // Verify that login form fields are present.
    expect(
      find.byType(TextFormField),
      findsAtLeastNWidgets(2),
    ); // Email and password fields
  });

  testWidgets('Login form validation works', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PayUniApp());

    // Find the Sign In button and tap it without entering credentials
    final signInButton = find.widgetWithText(ElevatedButton, 'Sign In');
    await tester.tap(signInButton);
    await tester.pump();

    // Verify that validation errors appear
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });
}
