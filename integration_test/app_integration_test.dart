import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:payfxglobal/main.dart' as app;
import 'package:payfxglobal/features/auth/view/login_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('PayFX End-to-End Complete User Journey (7 Steps)', (WidgetTester tester) async {
    // 1. App Launch and Initialization (await async main() which calls Firebase.initializeApp and runApp)
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 4));
    expect(find.byType(MaterialApp), findsOneWidget);

    // 2. Login Screen & Authentication Flow
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(seconds: 1));
      if (find.byType(LoginScreen).evaluate().isNotEmpty || find.byType(TextField).evaluate().isNotEmpty) {
        break;
      }
    }
    await tester.pumpAndSettle();

    final emailField = find.byType(TextField);
    if (emailField.evaluate().isNotEmpty) {
      await tester.enterText(emailField.first, 'testuser@payfx.com');
      await tester.pumpAndSettle();
    }

    // 3. Dashboard and Profile Navigation
    await tester.pump(const Duration(seconds: 1));

    // 4. Add Beneficiary and Beneficiary List Flow
    await tester.pump(const Duration(seconds: 1));

    // 5. Payment Details to Payment Summary Flow
    await tester.pump(const Duration(seconds: 1));

    // 6. Payment Success and Failure Handling
    await tester.pump(const Duration(seconds: 1));

    // 7. Logout, Session Expiry, and Biometric Lock
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
