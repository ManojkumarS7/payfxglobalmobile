import 'package:flutter/material.dart';
import 'package:payfxglobal/paystudy/core/constants/app_snackbar.dart';
import 'package:payfxglobal/utils/app_theme.dart';
import 'package:payfxglobal/widgets/custom_app_bar.dart';
import 'package:payfxglobal/widgets/custom_button.dart';
import 'package:payfxglobal/widgets/custom_loading_indicator.dart';
import '../service/choose_payment_method_service.dart';
import '../view_model/choose_payment_method_view_model.dart';


class ChoosePaymentMethodScreen extends StatefulWidget {
  final String? previousPage;

  const ChoosePaymentMethodScreen({
    super.key,
    this.previousPage,
  });

  @override
  State<ChoosePaymentMethodScreen> createState() =>
      _ChoosePaymentMethodScreenState();
}

class _ChoosePaymentMethodScreenState
    extends State<ChoosePaymentMethodScreen> {
  late ChoosePaymentMethodViewModel vm;

  @override
  void initState() {
    super.initState();

    vm = ChoosePaymentMethodViewModel(
      apiService: ChoosePaymentMethodApiService(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map<String, dynamic>) {
      vm.setInitialArgs(args).catchError((e) {
        if (!mounted) return;

        AppSnackbar.show(
          context,
          'Failed to select recipient',
          success: false,
        );
      });
    }
  }

  Future<void> _handleNext() async {
    if (vm.selectedMethod == 'offline') {
      try {
        final success = await vm.saveOfflinePaymentMode();

        if (!mounted) return;

        if (success) {
          Navigator.of(context).pushNamed(
            '/payment-success',
            arguments: {
              ...vm.responseData!,
              'payment_method': 'offline',
            },
          );
        } else {
          AppSnackbar.show(
            context,
            'Failed to save payment mode',
            success: false,
          );
        }
      } catch (e) {
        if (!mounted) return;

        AppSnackbar.show(
          context,
          'Something went wrong.. Check your internet',
          success: false,
        );
      }
    } else if (vm.selectedMethod == 'online') {
      final accepted = await _showOnlineChargesDialog();

      if (accepted == true) {
        try {
          await vm.saveOnlinePaymentMode();

          await vm.startOnlinePayment(
            // ==========================
            // PAYMENT SUCCESS
            // ==========================
            onPaymentSuccess: (orderId) {
              if (!mounted) return;

              Navigator.pushReplacementNamed(
                context,
                '/payment-success',
                arguments: {
                  ...vm.responseData!,
                  'order_id': orderId,
                  'payment_method': 'online',
                },
              );
            },

            // ==========================
            // PAYMENT PENDING
            // ==========================
            onPaymentPending: () {
              if (!mounted) return;

              AppSnackbar.show(
                context,
                'Payment is still pending',
                success: false,
              );
            },

            // ==========================
            // PAYMENT FAILED
            // ==========================
            onPaymentFailed: (message) {
              if (!mounted) return;

              AppSnackbar.show(
                context,
                'Payment failed',
                success: false,
              );
            },

            // ==========================
            // VERIFICATION FAILED
            // ==========================
            onVerificationFailed: (message) {
              if (!mounted) return;

              AppSnackbar.show(
                context,
                'Verification failed',
                success: false,
              );
            },

            // ==========================
            // USER CANCELLED PAYMENT
            // ==========================
            onPaymentCancelled: () {
              if (!mounted) return;

              Navigator.of(context).pushNamedAndRemoveUntil(
                '/dashboard',
                    (route) => false,
              );
            },
          );
        } catch (e) {
          debugPrint('Payment Error: $e');

          if (!mounted) return;

          AppSnackbar.show(
            context,
            'Something went wrong',
            success: false,
          );
        }
      }
    }
  }




  Future<bool?> _showOnlineChargesDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Online Payment Charges',
            style: TextStyle(
              fontFamily: 'Satoshi',
              color: AppTheme.PrimaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          content: const Text(
            'UPI - ₹10 + GST 18% = ₹11.80 per transaction\n\n'
                'Net Banking - ₹55 + GST 18% = ₹64.90 per transaction\n\n'
                'Card - 0.9% on total amount + GST',
            style: TextStyle(
              fontFamily: 'Satoshi',
              color: AppTheme.TextColor,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  color: AppTheme.TextColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Accept',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  color: AppTheme.TextColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showTermsAndConditions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Terms & Conditions',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: const [
                        Text(
                          '''
PAYMENT TERMS & CONDITIONS
PAYFX GLOBAL

PayFX Global is a brand of PayFX Fintech Solutions Private Limited providing international payment facilitation, foreign exchange assistance, institutional payment solutions, and cross-border remittance support through regulated banking and financial institution partnerships.

By initiating, authorizing, or completing any payment transaction through PayFX Global, you agree to these Terms & Conditions.

1. GENERAL TERMS
All transactions processed through PayFX Global are subject to RBI/FEMA regulations, AML/KYC compliance requirements, banking policies, taxation, and regulatory laws.

2. ONLINE PAYMENT TERMS
Online payments may be processed through authorized banking partners, payment aggregators, card networks, UPI systems, net banking channels, or regulated financial institutions.

3. OFFLINE PAYMENT TERMS
Customers must ensure payment is made only to the official bank account mentioned in the payment instruction and the correct reference number is used.

4. FOREIGN EXCHANGE AND SETTLEMENT
Exchange rates may vary based on market conditions and banking partner pricing. Additional charges may apply.

5. REFUNDS AND REVERSALS
Refunds are subject to compliance approval, receiving institution approval, banking policies, and regulatory requirements.

6. FRAUD PREVENTION AND COMPLIANCE
PayFX Global reserves the right to reject suspicious transactions, request documents, hold transactions, or report suspicious activity.

7. LIMITATION OF LIABILITY
PayFX Global shall not be liable for banking delays, technical failures, gateway downtime, exchange rate fluctuations, or incorrect customer information.

8. DATA PRIVACY
Customer information and payment details shall be collected and processed according to applicable laws and PayFX Global Privacy Policy.

Support Email: care@payfxglobal.com
Privacy Email: privacy@payfxglobal.com
''',
                          style: TextStyle(
                            fontFamily: 'Satoshi',
                            fontSize: 14,
                            height: 1.5,
                            color: AppTheme.TextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: vm,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: const AppPrimaryAppBar(
            title: 'Payment Mode',
          ),
          body: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    const Text(
                      'Select Payment Mode',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.TextColor,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Choose how you want to fund your transfer.',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 32),

                    _buildOption(
                      icon: Icons.account_balance_outlined,
                      label: 'Offline Method',
                      value: 'offline',
                    ),


                    const SizedBox(height: 16),

                    if (!vm.isGiftReason) ...[
                      const SizedBox(height: 16),
                      _buildOption(
                        icon: Icons.bolt_outlined,
                        label: 'Online Method',
                        value: 'online',
                      ),
                    ],

                    const Spacer(),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: vm.termsAccepted,
                              onChanged: (value) {
                                vm.setTermsAccepted(
                                  value ?? false,
                                );
                              },
                              activeColor:
                              AppTheme.PrimaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(4),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: GestureDetector(
                              onTap: _showTermsAndConditions,
                              child: RichText(
                                text: const TextSpan(
                                  style: TextStyle(
                                    fontFamily: 'Satoshi',
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'I agree to the ',
                                    ),
                                    TextSpan(
                                      text:
                                      'Payment Terms & Conditions',
                                      style: TextStyle(
                                        color:
                                        AppTheme.PrimaryColor,
                                        fontWeight:
                                        FontWeight.w600,
                                        decoration:
                                        TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    AppPrimaryButton(
                      title: 'Next',
                      loading: vm.isLoading,
                      onPressed:
                      vm.canProceed ? _handleNext : null,
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),

              if (vm.isLoading) const LoadingOverlay(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String label,
    required String value,
    bool enabled = true,
    Widget? trailing,
  }) {
    final bool isSelected = vm.selectedMethod == value;
    final primaryColor = AppTheme.PrimaryColor;

    return GestureDetector(
      onTap: enabled
          ? () => vm.setPaymentMethod(value)
          : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: primaryColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor.withOpacity(0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? primaryColor
                    : Colors.black45,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? primaryColor
                          : AppTheme.TextColor,
                    ),
                  ),
                  if (value == 'online')
                    Text(
                      'Instant payment via UPI/Netbanking',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 12,
                        color: isSelected
                            ? primaryColor.withOpacity(0.7)
                            : Colors.black45,
                      ),
                    ),
                  if (value == 'offline')
                    Text(
                      'Manual bank transfer',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 12,
                        color: isSelected
                            ? primaryColor.withOpacity(0.7)
                            : Colors.black45,
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing,
            Radio<String>(
              value: value,
              groupValue: vm.selectedMethod,
              onChanged: enabled
                  ? (value) => vm.setPaymentMethod(value)
                  : null,
              activeColor: primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.1),
      child: const Center(
        child: CustomLoadingIndicator(),
      ),
    );
  }
}
