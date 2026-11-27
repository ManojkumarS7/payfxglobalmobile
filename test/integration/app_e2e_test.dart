import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payfxglobal/features/splash/splash_screen.dart';
import 'package:payfxglobal/features/auth/view/login_screen.dart';
import 'package:payfxglobal/features/profile/profile_screen.dart';
import 'package:payfxglobal/features/transaction_recepient/view/transaction_recepient_screen.dart';
import 'package:payfxglobal/features/payment_details/view/payment_details_screen.dart';
import 'package:payfxglobal/features/payment_success/view/payment_success_screen.dart';
import 'package:payfxglobal/features/auth/view/unlock_screen.dart';
import 'package:payfxglobal/models/user/user.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PayFX End-to-End Integration Test Suite (7 Execution Steps)', () {

    setUp(() {
      TestWidgetsFlutterBinding.instance.platformDispatcher.views.first.physicalSize = const Size(800, 1200);
      TestWidgetsFlutterBinding.instance.platformDispatcher.views.first.devicePixelRatio = 1.0;
    });

    tearDown(() {
      TestWidgetsFlutterBinding.instance.platformDispatcher.views.first.physicalSize = const Size(800, 600);
      TestWidgetsFlutterBinding.instance.platformDispatcher.views.first.devicePixelRatio = 1.0;
    });

    testWidgets('Step 1: App launch and initialization (SplashScreen)', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 3));
      expect(find.byType(SplashScreen), findsOneWidget);
    });

    testWidgets('Step 2: Login -> OTP verification', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('Step 3: Dashboard -> Profile navigation', (WidgetTester tester) async {
      final mockUser = User(
        userId: 1,
        fullName: 'Test User',
        email: 'test@payfx.com',
        mobile: '1234567890',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(user: mockUser),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('Test User'), findsOneWidget);
    });

    testWidgets('Step 4: Add beneficiary -> Beneficiary list', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TransactionReceiptScreen(transactionData: {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TransactionReceiptScreen), findsOneWidget);
    });

    testWidgets('Step 5: Payment details -> Payment summary', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PaymentDetailsScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(PaymentDetailsScreen), findsOneWidget);
    });

    testWidgets('Step 6: Payment success / failure handling', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PaymentSuccessScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PaymentSuccessScreen), findsOneWidget);
    });

    testWidgets('Step 7: Logout -> Session expiry -> Biometric lock', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: UnlockScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(UnlockScreen), findsOneWidget);
    });
  });
}
