import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payfxglobal/features/dashboard/view/currency_rate_view.dart';
import 'package:payfxglobal/paystudy/features/account_opening/account_opening.dart';
import 'package:payfxglobal/features/intro_screen/intro_screen.dart';
import 'package:payfxglobal/features//profile/profile_screen.dart';
import 'package:payfxglobal/services/notification_service.dart';
import 'features/auth/view/forgot_password_otp_screen.dart';
import 'features/auth/view/forgot_password_reset_screen.dart';
import 'features/auth/view/forgot_password_screen.dart';
import 'features/auth/view/identify_verification_screen.dart';
import 'features/payment_details/view/payment_details_screen.dart';
import 'features/transaction_history/view/transaction_history_screen.dart';
import 'features/transaction_recepient/view/transaction_recepient_screen.dart';
import 'features/transaction_details/view/transaction_detail_screen.dart';
import 'package:payfxglobal/services/api_service.dart';
import 'package:payfxglobal/utils/app_theme.dart';
import 'package:payfxglobal/utils/app_constants.dart';
import 'features/auth/view/login_screen.dart';
import 'package:payfxglobal/features/welcome/welcome_screen.dart';
import 'package:payfxglobal/features/auth/view/email_entry_screen.dart';
import 'features/dashboard/view/dashboard_view.dart';
import 'features/auth/view/password_entry_screen.dart';
import 'package:payfxglobal/features/auth/view/upload _document_screen.dart';
import 'features/update_recepient/view/update_delivery_method_screen.dart';
import 'features/payment_success/view/payment_success_screen.dart';
import 'features/money_transfer/view/money_transfer_screen.dart';
import 'features/choose_payment_method/view/choose_payment_method_screen.dart';
import 'features/payment_summary/view/payment_summary_screen.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/view/delete_account_screen.dart';
import 'package:payfxglobal/models/user/user.dart';
import 'package:payfxglobal/utils/session_manager.dart';
import 'paystudy/features/home/home_dashboard.dart';
import 'paystudy/features/aboutus/about_usPage.dart';
import 'paystudy/features/support/support_page.dart';
import 'package:payfxglobal/features/auth/view/unlock_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'features/payment_tcs/view/payment_tcs_page.dart';
import 'features/auth/view/sender_detail_screen.dart';


// Key for accessing navigator globally (referenced in SessionManager)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await ApiService.initializeApiKey();

  runApp(
    const ProviderScope(
      child: PayUniApp(),
    ),
  );

  SessionManager().initialize();
  NotificationService.initialize();
}


class PayUniApp extends StatelessWidget {
  const PayUniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: AppConstants.appName,
      theme: AppTheme.lightTheme.copyWith(
        scaffoldBackgroundColor: Colors.white,
        canvasColor: Colors.white,
      ),
      darkTheme: AppTheme.lightTheme.copyWith(
        scaffoldBackgroundColor: Colors.white,
        canvasColor: Colors.white,
      ),
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),

      routes: {

        '/splash': (context) => const SplashScreen(),
        '/intro': (context) => const IntroScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/email-entry': (context) => const EmailEntryScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/forgot-password-otp': (context) => const ForgotPasswordOtpScreen(),
        '/forgot-password-reset': (context) => const ForgotPasswordResetScreen(),
        '/password-entry': (context) => const PasswordEntryScreen(),
        '/identity-verification': (context) => const IdentityVerificationScreen(),
        '/dashboard': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final userData = (args is Map && args['userData'] != null)
              ? Map<String, dynamic>.from(args['userData'])
              : <String, dynamic>{};

          return DashboardScreen(userData: userData);
        },
        '/upload-documents': (context) => const UploadDocumentsScreen(),
        '/payment-details': (context) => const PaymentDetailsScreen(),
        '/payment-details-update': (context) => const UpdateDeliveryMethodScreen(),
        '/choose-payment-method': (context) => const ChoosePaymentMethodScreen(),
        '/payment-success': (context) => const PaymentSuccessScreen(),
        '/money-transfer': (context) {
          final args = (ModalRoute.of(context)?.settings.arguments as Map<dynamic, dynamic>?)?.cast<String, dynamic>() ?? {};
          return MoneyTransferScreen(
            userData: (args['userData'] as Map?)?.cast<String, dynamic>() ?? {},
            transferType: args['transferType']?.toString(),
            isNewUser: args['isNewUser'] == true,
          );
        },
        '/payment-summary': (context) => const PaymentSummaryScreen(),
        '/transaction-history': (context) {
          final args =
              (ModalRoute.of(context)?.settings.arguments
              as Map<dynamic, dynamic>?)
                  ?.cast<String, dynamic>() ??
                  {};
          final userId = int.tryParse(args['user_id']?.toString() ?? '') ?? 0;
          return TransactionHistoryScreen(userId: userId);
        },
        '/transaction-detail': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          return TransactionDetailScreen(transaction: args);
        },

        '/profile': (context) {
          final user = ModalRoute.of(context)!.settings.arguments as User;
          return ProfileScreen(user: user);
        },

        '/delete-account': (context) => const DeleteAccountScreen(),
         '/sender-details': (context) => const SenderDetailsScreen(),

        '/transaction-receipt': (context) {
          final args = (ModalRoute.of(context)?.settings.arguments as Map<dynamic, dynamic>?)?.cast<String, dynamic>() ?? {};
          return TransactionReceiptScreen(transactionData: args);
        },

        '/account-opening': (context) => const AccountOpening(),
        '/education-loan': (context) => const PaystudyDashboardScreen(),
        '/about-us': (context) => const AboutUspage(),
        '/support' : (context) => const SupportPage(),
        '/unlock': (context) => const UnlockScreen(),
        '/payment-terms': (context) => const PaymentTermsScreen(),
        '/currency-rates': (context) => const CurrencyRateView(),
      },
    );
  }
}
