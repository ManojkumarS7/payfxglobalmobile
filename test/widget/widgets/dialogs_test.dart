import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payfxglobal/widgets/app_snackbar.dart';
import 'package:payfxglobal/widgets/ekyc_dialog.dart';
import 'package:payfxglobal/widgets/profile_created_dialog.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('EKycDialog Widget Tests', () {
    testWidgets('Displays e-KYC header, instruction text, and handles Continue tap', (tester) async {
      bool continueTapped = false;

      await tester.pumpWidget(
        createTestWidget(
          EKycDialog(
            onContinue: () {
              continueTapped = true;
            },
          ),
        ),
      );

      expect(find.text('Complete Your e-KYC Verification'), findsOneWidget);
      expect(find.textContaining('A secure e-KYC link has been sent'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      expect(continueTapped, true);
    });
  });

  group('ProfileCreatedDialog Widget Tests', () {
    testWidgets('Displays success title, check icon, and description', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const ProfileCreatedDialog(
            userData: {'user_id': 101, 'name': 'John'},
          ),
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Profile successfully created.'), findsOneWidget);
      expect(find.text('Your profile is ready. You can now start using PayFX Global.'), findsOneWidget);
      expect(find.text('Go to Home'), findsOneWidget);
    });
  });

  group('AppSnackbar Tests', () {
    testWidgets('Displays success snackbar with message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppSnackbar.show(context, 'Operation Successful', success: true),
                child: const Text('Show Success'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Success'));
      await tester.pump();

      expect(find.text('Operation Successful'), findsOneWidget);
    });

    testWidgets('Displays error snackbar with message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppSnackbar.show(context, 'Something went wrong', success: false),
                child: const Text('Show Error'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Error'));
      await tester.pump();

      expect(find.text('Something went wrong'), findsOneWidget);
    });
  });
}
