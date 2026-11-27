import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payfxglobal/widgets/app_snackbar.dart';

void main() {
  group('AppSnackbar Widget Tests', () {
    testWidgets('Shows floating success snackbar with message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppSnackbar.show(
                  context,
                  'Profile updated successfully',
                  success: true,
                ),
                child: const Text('Show Success'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Success'));
      await tester.pump();

      expect(find.text('Profile updated successfully'), findsOneWidget);
    });

    testWidgets('Shows floating error snackbar with message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppSnackbar.show(
                  context,
                  'Failed to update profile',
                  success: false,
                ),
                child: const Text('Show Error'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Error'));
      await tester.pump();

      expect(find.text('Failed to update profile'), findsOneWidget);
    });
  });
}
