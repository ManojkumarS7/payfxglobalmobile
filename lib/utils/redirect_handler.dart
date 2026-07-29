// import 'package:flutter/material.dart';
// import 'package:payfxglobal/screens/dashboard/dashboard_screen.dart';
// import 'package:payfxglobal/screens/sender_details_screen.dart';
// import 'package:payfxglobal/screens/identity_verification_screen.dart';
// import 'package:payfxglobal/screens/upload_documents_screen.dart';
// import 'package:payfxglobal/screens/questions_screen.dart';
// import 'package:payfxglobal/screens/auth/password_entry_screen.dart';
// import 'package:payfxglobal/screens/auth/otp_verification_screen.dart';
// import 'package:payfxglobal/screens/services_offered_screen.dart';
// import 'package:payfxglobal/screens/payment_details_screen.dart';
//
// /// 🔄 Master Redirect Handler - Handles complete user flow
// /// Checks: password, OTP, sender_details, questions_answers, delivery_method_details, transactions
// class RedirectHandler {
//   /// 🎯 Main redirect function - Route based on complete profile state
//   static void handleMasterRedirect(
//     BuildContext context,
//     Map<String, dynamic> redirectResponse,
//   ) {
//     try {
//       final nextPage = redirectResponse['next_page'] ?? 'dashboard';
//       final data = redirectResponse['data'] ?? {};
//       final email = redirectResponse['email'] ?? '';
//
//       debugPrint('🔄 Master Redirect: $nextPage with data: $data');
//
//       switch (nextPage.toLowerCase()) {
//         // ❌ STEP 1: Password not set
//         case 'password_entry':
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (_) => const PasswordEntryScreen(),
//               settings: RouteSettings(arguments: {'email': email}),
//             ),
//           );
//           break;
//
//         // // ❌ STEP 2: OTP not verified
//         // case 'otp_verification':
//         //   Navigator.push(
//         //     context,
//         //     MaterialPageRoute(
//         //       builder: (_) => const OtpVerificationScreen(),
//         //       settings: RouteSettings(
//         //         arguments: {'email': email, 'otp': data['otp']?.toString()},
//         //       ),
//         //     ),
//         //   );
//         //   break;
//
//         // ✅ STEP 3: Password + OTP filled → Services offered
//         case 'services_offered':
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (_) => const ServicesOfferedScreen(),
//               settings: RouteSettings(
//                 arguments: {
//                   'user_id': data['user_id'],
//                   'email': email,
//                   'service': 'money_transfer',
//                 },
//               ),
//             ),
//           );
//           break;
//
//         // ✅ STEP 4: Sender details missing → Identity verification
//         case 'identity_verification':
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (_) => const IdentityVerificationScreen(),
//               settings: RouteSettings(
//                 arguments: {
//                   'user_id': data['user_id'],
//                   'email': email,
//                   'send_amount': data['send_amount'],
//                   'recipient_amount': data['recipient_amount'],
//                   'currency': data['currency'],
//                   'transaction_id': data['transaction_id'],
//                   'transaction_code': data['transaction_code'],
//                 },
//               ),
//             ),
//           );
//           break;
//
//         // ✅ STEP 5: Sender details exist → Sender details screen
//         case 'sender_details':
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (_) => const SenderDetailsScreen(),
//               settings: RouteSettings(
//                 arguments: {
//                   'user_id': data['user_id'],
//                   'email': email,
//                   'service': data['service'] ?? 'money_transfer',
//                   'name': data['name'] ?? '',
//                   'dob': data['dob'] ?? '',
//                   'aadhaar': data['aadhaar'] ?? '',
//                   'aadhaar_linked': data['aadhaar_linked'] ?? false,
//                   'address': data['address'] ?? {},
//                 },
//               ),
//             ),
//           );
//           break;
//
//         // ✅ STEP 6: Questions answers missing → Questions screen
//         case 'questions':
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (_) => const QuestionsScreen(),
//               settings: RouteSettings(
//                 arguments: {
//                   'user_id': data['user_id'],
//                   'email': email,
//                   'transaction_id': data['transaction_id'],
//                   'send_amount': data['send_amount'],
//                   'recipient_amount': data['recipient_amount'],
//                 },
//               ),
//             ),
//           );
//           break;
//
//         // ✅ STEP 7: Questions filled → Upload documents
//         case 'upload_documents':
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (_) => const UploadDocumentsScreen(),
//               settings: RouteSettings(
//                 arguments: {
//                   'user_id': data['user_id'],
//                   'email': email,
//                   'transaction_id': data['transaction_id'],
//                 },
//               ),
//             ),
//           );
//           break;
//
//         // ✅ STEP 8: Documents uploaded, signin_id missing → Payment details
//         case 'payment_details':
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (_) => const PaymentDetailsScreen(),
//               settings: RouteSettings(
//                 arguments: {
//                   'user_id': data['user_id'],
//                   'email': email,
//                   'transaction_id': data['transaction_id'],
//                   'occupation_id': data['occupation_id'],
//                   'source_of_fund_id': data['source_of_fund_id'],
//                   'income_range': data['income_range'],
//                   'pep_status': data['pep_status'],
//                 },
//               ),
//             ),
//           );
//           break;
//
//         // ✅ STEP 9: All data complete → Dashboard
//         case 'dashboard':
//         default:
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//               builder: (_) => DashboardScreen(
//                 userData: {
//                   'user_id': data['user_id'],
//                   'email': email,
//                   'dashboard': data['dashboard'] ?? {},
//                   ...data,
//                 },
//               ),
//             ),
//           );
//           break;
//       }
//     } catch (e) {
//       debugPrint('❌ Redirect error: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Navigation error: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
//
//   /// Get the appropriate route based on page name
//   static String getRoute(String nextPage) {
//     switch (nextPage.toLowerCase()) {
//       case 'password_entry':
//         return '/password-entry';
//       case 'otp_verification':
//         return '/otp-verification';
//       case 'services_offered':
//         return '/services-offered';
//       case 'identity_verification':
//         return '/identity-verification';
//       case 'sender_details':
//         return '/sender-details';
//       case 'questions':
//         return '/questions';
//       case 'upload_documents':
//         return '/upload-documents';
//       case 'payment_details':
//         return '/payment-details';
//       case 'dashboard':
//       default:
//         return '/dashboard';
//     }
//   }
//
//   /// Get page display name
//   static String getPageName(String nextPage) {
//     switch (nextPage.toLowerCase()) {
//       case 'password_entry':
//         return 'Set Password';
//       case 'otp_verification':
//         return 'Verify OTP';
//       case 'services_offered':
//         return 'Services';
//       case 'identity_verification':
//         return 'Identity Verification';
//       case 'sender_details':
//         return 'Sender Details';
//       case 'questions':
//         return 'Answer Questions';
//       case 'upload_documents':
//         return 'Upload Documents';
//       case 'payment_details':
//         return 'Payment Details';
//       case 'dashboard':
//       default:
//         return 'Dashboard';
//     }
//   }
//
//   /// Get progress percentage
//   static double getProgress(String nextPage) {
//     switch (nextPage.toLowerCase()) {
//       case 'password_entry':
//         return 0.1;
//       case 'otp_verification':
//         return 0.2;
//       case 'services_offered':
//         return 0.3;
//       case 'identity_verification':
//         return 0.4;
//       case 'sender_details':
//         return 0.5;
//       case 'questions':
//         return 0.65;
//       case 'upload_documents':
//         return 0.8;
//       case 'payment_details':
//         return 0.9;
//       case 'dashboard':
//       default:
//         return 1.0;
//     }
//   }
// }
