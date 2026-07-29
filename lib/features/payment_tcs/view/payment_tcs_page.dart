import 'package:flutter/material.dart';
import 'package:payfxglobal/utils/app_theme.dart';
import 'package:payfxglobal/widgets/custom_app_bar.dart';


class PaymentTermsScreen extends StatelessWidget {
  const PaymentTermsScreen({super.key});

  static const Color _navy = AppTheme.TextColor;
  static const Color _amber = AppTheme.PrimaryColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppPrimaryAppBar(title: 'Payment Terms & Conditions'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 24),

              _sectionTitle('1. General Terms'),
              _bulletParagraph(
                '1.1 All transactions processed through PayFX Global are subject to applicable:',
                [
                  'RBI/FEMA regulations',
                  'AML/KYC compliance requirements',
                  'Banking and financial institution policies',
                  'Applicable taxation and regulatory laws',
                ],
              ),
              _plainParagraph(
                '1.2 PayFX Global reserves the right to request additional documents, verification, or information before processing any transaction.',
              ),
              _plainParagraph(
                '1.3 Customers are solely responsible for ensuring that all payment details, beneficiary details, and transaction information submitted are accurate and complete.',
              ),

              _sectionTitle('2. Online Payment Terms', subtitle: '(Payment Gateway Transactions)'),
              _subheading('2.1 Payment Processing'),
              _plainParagraph(
                'Online payments made through the PayFX Global payment gateway may be processed through authorized banking partners, payment aggregators, card networks, UPI systems, net banking channels, or regulated financial institutions.',
              ),
              _subheading('2.2 Authorization'),
              _bulletParagraph(
                'By proceeding with an online payment, you authorize PayFX Global and its authorized payment partners to:',
                [
                  'Process the transaction',
                  'Debit the selected payment method',
                  'Conduct verification and compliance checks',
                  'Process currency conversion where applicable',
                ],
              ),
              _subheading('2.3 Transaction Verification'),
              _bulletParagraph(
                'Online transactions may be subject to:',
                [
                  'OTP authentication',
                  '3D Secure verification',
                  'Fraud and risk monitoring',
                  'KYC/AML verification',
                  'Additional security validation',
                ],
              ),
              _plainParagraph(
                'PayFX Global reserves the right to hold, reject, or cancel transactions identified as suspicious or non-compliant.',
              ),
              _subheading('2.4 Failed or Declined Transactions'),
              _bulletParagraph(
                'PayFX Global shall not be responsible for payment failures caused by:',
                [
                  'Banking system downtime',
                  'Card issuer restrictions',
                  'Insufficient balance',
                  'Technical interruptions',
                  'Payment gateway failures',
                  'Incorrect payment details',
                  'Regulatory restrictions',
                ],
              ),
              _plainParagraph(
                'Any debited amount for failed transactions shall be refunded subject to banking and payment partner timelines.',
              ),

              _sectionTitle('3. Offline Payment Terms', subtitle: '(Payment Instruction / Bank Transfer Transactions)'),
              _subheading('3.1 Payment Instructions'),
              _bulletParagraph(
                'Customers may receive a payment instruction issued by PayFX Global containing:',
                [
                  'Beneficiary details',
                  'Bank account information',
                  'Currency and amount payable',
                  'Reference or transaction number',
                  'Payment timelines and conditions',
                ],
              ),
              _subheading('3.2 Customer Responsibility'),
              _bulletParagraph(
                'Customers must ensure:',
                [
                  'Payment is made only to the official bank account mentioned in the payment instruction',
                  'The exact payment reference/instruction number is quoted during remittance',
                  'Funds are transferred from lawful and verifiable sources',
                  'Payment is completed within the validity period of the instruction',
                ],
              ),
              _subheading('3.3 Verification and Allocation'),
              _bulletParagraph(
                'Offline payments shall be processed only after:',
                [
                  'Receipt of cleared funds',
                  'Internal transaction verification',
                  'Compliance and KYC review',
                  'Confirmation of payment details',
                ],
              ),
              _bulletParagraph(
                'Customers may be required to upload or submit:',
                [
                  'UTR/transaction reference number',
                  'Payment receipt',
                  'Bank transfer confirmation',
                  'Supporting invoices or documents',
                ],
              ),
              _subheading('3.4 Delayed or Unidentified Payments'),
              _bulletParagraph(
                'PayFX Global shall not be liable for delays caused due to:',
                [
                  'Missing transaction references',
                  'Incorrect payment information',
                  'Delayed banking systems',
                  'Intermediary bank processing',
                  'Compliance review or regulatory checks',
                ],
              ),
              _plainParagraph(
                'Unidentified funds may remain on hold until proper verification is completed.',
              ),

              _sectionTitle('4. Foreign Exchange and Settlement'),
              _plainParagraph(
                '4.1 Where applicable, foreign exchange conversion rates shall be determined at the time of processing and may vary based on market conditions and banking partner pricing.',
              ),
              _bulletParagraph(
                '4.2 Additional charges may apply including:',
                [
                  'Banking fees',
                  'Currency conversion margins',
                  'Intermediary bank charges',
                  'Payment gateway fees',
                  'Taxes and regulatory charges',
                ],
              ),
              _plainParagraph(
                '4.3 Final settlement amounts may vary due to exchange rate fluctuations and third-party deductions.',
              ),

              _sectionTitle('5. Refunds and Reversals'),
              _bulletParagraph(
                '5.1 Refunds are subject to:',
                [
                  'Compliance approval',
                  'Receiving institution or beneficiary approval',
                  'Applicable banking policies',
                  'Regulatory requirements',
                ],
              ),
              _plainParagraph(
                '5.2 Refund processing timelines depend on banking partners, card issuers, intermediary institutions, and applicable jurisdictions.',
              ),
              _bulletParagraph(
                '5.3 Any applicable amounts below may be deducted from refund amounts:',
                [
                  'Currency fluctuation losses',
                  'Banking charges',
                  'Gateway fees',
                  'Intermediary deductions',
                ],
              ),

              _sectionTitle('6. Fraud Prevention and Compliance'),
              _bulletParagraph(
                'PayFX Global reserves the right to:',
                [
                  'Reject suspicious transactions',
                  'Conduct enhanced due diligence',
                  'Request additional documentation',
                  'Hold or suspend transactions',
                  'Report suspicious activity to regulatory or law enforcement authorities',
                ],
              ),
              _bulletParagraph(
                'Customers shall not use the services for:',
                [
                  'Fraudulent transactions',
                  'Money laundering',
                  'Sanctions violations',
                  'Illegal financial activities',
                  'Unauthorized third-party payments',
                ],
              ),

              _sectionTitle('7. Limitation of Liability'),
              _bulletParagraph(
                'PayFX Global and PayFX Fintech Solutions Private Limited shall not be liable for:',
                [
                  'Banking delays',
                  'Technical failures',
                  'Payment gateway downtime',
                  'Exchange rate fluctuations',
                  'Third-party processing failures',
                  'Regulatory restrictions',
                  'Incorrect information provided by customers',
                ],
              ),
              _plainParagraph(
                'All services are provided on an "AS IS" and "AS AVAILABLE" basis.',
              ),

              _sectionTitle('8. Data Privacy'),
              _bulletParagraph(
                'Customer information and payment details shall be collected and processed in accordance with:',
                [
                  'Applicable Indian IT laws',
                  'DPDP Act, 2023',
                  'RBI/FEMA guidelines',
                  'PayFX Global Privacy Policy',
                ],
              ),

              _sectionTitle('9. Customer Declaration'),
              _bulletParagraph(
                'By proceeding with any online or offline payment, you confirm that:',
                [
                  'The funds belong to you or are legally authorized',
                  'All submitted information is accurate and lawful',
                  'You agree to comply with these Terms & Conditions',
                  'You authorize PayFX Global to process the transaction and conduct compliance verification where required',
                ],
              ),

              const SizedBox(height: 24),
              _buildFooterCard(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Header intro card
  // ---------------------------------------------------------------------
  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF5FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.description_outlined, color: _navy, size: 20),
              SizedBox(width: 8),
              Text(
                'PayFX Global',
                style: TextStyle(fontFamily: 'Satoshi', fontSize: 16, fontWeight: FontWeight.w800, color: _navy),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Applicable for Online and Offline Payment Instructions',
            style: TextStyle(fontFamily: 'Satoshi', fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 10),
          Text(
            'PayFX Global is a brand of PayFX Fintech Solutions Private Limited providing international payment facilitation, foreign exchange assistance, institutional payment solutions, and cross-border remittance support through regulated banking and financial institution partnerships.',
            style: TextStyle(fontFamily: 'Satoshi', fontSize: 13, height: 1.5, color: Colors.grey.shade800),
          ),
          const SizedBox(height: 10),
          Text(
            'By initiating, authorizing, or completing any payment transaction through PayFX Global, you ("Customer", "User", or "Payer") agree to these Terms & Conditions.',
            style: TextStyle(fontFamily: 'Satoshi', fontSize: 13, height: 1.5, fontWeight: FontWeight.w600, color: _navy),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Footer contact card
  // ---------------------------------------------------------------------
  Widget _buildFooterCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PayFX Global',
            style: TextStyle(fontFamily: 'Satoshi', fontSize: 15, fontWeight: FontWeight.w800, color: _navy),
          ),
          const SizedBox(height: 4),
          Text(
            'A Brand of PayFX Fintech Solutions Private Limited',
            style: TextStyle(fontFamily: 'Satoshi', fontSize: 12.5, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          _contactRow(Icons.email_outlined, 'Support', 'care@payfxglobal.com'),
          const SizedBox(height: 8),
          _contactRow(Icons.privacy_tip_outlined, 'Privacy', 'privacy@payfxglobal.com'),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String label, String email) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _amber),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(fontFamily: 'Satoshi', fontSize: 12.5, fontWeight: FontWeight.w700, color: _navy),
        ),
        Text(
          email,
          style: TextStyle(fontFamily: 'Satoshi', fontSize: 12.5, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Reusable section builders
  // ---------------------------------------------------------------------
  Widget _sectionTitle(String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(color: _amber, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontFamily: 'Satoshi', fontSize: 16.5, fontWeight: FontWeight.w800, color: _navy),
                ),
              ),
            ],
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(left: 14, top: 2),
              child: Text(
                subtitle,
                style: TextStyle(fontFamily: 'Satoshi', fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
              ),
            ),
        ],
      ),
    );
  }

  Widget _subheading(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(
        text,
        style: const TextStyle(fontFamily: 'Satoshi', fontSize: 14, fontWeight: FontWeight.w700, color: _navy),
      ),
    );
  }

  Widget _plainParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        style: TextStyle(fontFamily: 'Satoshi', fontSize: 13, height: 1.55, color: Colors.grey.shade800),
      ),
    );
  }

  Widget _bulletParagraph(String intro, List<String> bullets) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            intro,
            style: TextStyle(fontFamily: 'Satoshi', fontSize: 13, height: 1.55, color: Colors.grey.shade800),
          ),
          const SizedBox(height: 6),
          ...bullets.map(
                (b) => Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(Icons.circle, size: 5, color: _amber),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      b,
                      style: TextStyle(fontFamily: 'Satoshi', fontSize: 13, height: 1.5, color: Colors.grey.shade800),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}