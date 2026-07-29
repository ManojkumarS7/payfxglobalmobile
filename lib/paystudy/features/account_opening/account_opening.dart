import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:payfxglobal/paystudy/core/constants/app_colors.dart';
import 'package:payfxglobal/paystudy/core/constants/app_textfield.dart';
import 'package:file_picker/file_picker.dart';
import 'package:payfxglobal/paystudy/core/constants/app_snackbar.dart';
import 'dart:convert';

class AccountOpening extends StatefulWidget {
  const AccountOpening({super.key});

  @override
  State<AccountOpening> createState() => _AccountOpeningState();
}

class _AccountOpeningState extends State<AccountOpening> {
  final _formKey = GlobalKey<FormState>();
  String _selectedAccountType = 'GIC';
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  String? _selectedBank;

  File? offer_letter;
  File? front_passport;
  File? back_passport;

  bool _showBill = false;
  Map<String, dynamic>? _selectedBankDetails;




  final Map<String, Map<String, dynamic>> _bankData = {
    'Blocked Account': {
      'Studley': {
        'amount': 11974,
        'currency': 'EUR',
        'recommended': true,
        'details': '*Save Eur 179\n*Customer call center available in India'
      },
      'Expartio': {'amount': 12153, 'currency': 'EUR'},
      'Coracle': {'amount': 12083, 'currency': 'EUR'},
      'Fintiba': {'amount': 11993, 'currency': 'EUR'},
    },
    'GIC': {
      'CIBC': {'amount': 23124, 'currency': 'CAD'},
      'ICICI Canada': {'amount': 23120, 'currency': 'CAD'},
      'Bank of Nova scotia': {'amount': 23095, 'currency': 'CAD'},
      'BMO': {'amount': 23050, 'currency': 'CAD'},
      'Royal Bank of Canada': {'amount': 23145, 'currency': 'CAD'},
      'Beacon': {'amount': 25150, 'currency': 'CAD'},
    }
  };


  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _formKey.currentState?.reset();

    setState(() {
      _selectedAccountType = 'GIC';
      _selectedBank = null;
      _selectedBankDetails = null;
      offer_letter = null;
      front_passport = null;
      back_passport = null;
      _showBill = false;
    });
  }

  Future<void> pickFile(String type) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null) {
      setState(() {
        if (type == 'offer') {
          offer_letter = File(result.files.single.path!);
        } else if (type == 'front') {
          front_passport = File(result.files.single.path!);
        } else if (type == 'back') {
          back_passport = File(result.files.single.path!);
        }
      });
    }
  }

  Future<void> _sendEmailNotification() async {
    final String userEmail = _emailController.text.trim();
    final String userName = _nameController.text.trim();
    final String userPhone = _phoneController.text.trim();
    final String bankName = _selectedBank ?? '';
    final String amount = "${_selectedBankDetails?['currency']} ${_selectedBankDetails?['amount']}";

    final dio = Dio();
    const String url = "https://api.zeptomail.in/v1.1/email";
    const String apiKey =
        "PHtE6r0PFrjo2TYo9hACtPHqE8GjPIos+uo0KwcRsNtHAvULHU1Xo4gomzO1+h1+V6VEHKSbzto65O6fs+PQI2zlMTtOW2qyqK3sx/VYSPOZsbq6x00ctVUedkfYXIDvdtJj1izWsteX";

    final String htmlBody = """
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Account Opening Request</title>
</head>
<body style="margin:0; padding:0; background-color:#f0f0f0; font-family: Arial, sans-serif;">

  <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#f0f0f0; padding: 30px 0;">
    <tr>
      <td align="center">
        <table width="600" cellpadding="0" cellspacing="0" style="background-color:#ffffff;">


          <tr>
            <td style="background-color:#363D59; padding: 24px 40px;">
              <img src="https://www.payfxglobal.com/assets/img/logo.png"
                   alt="PayFX Global"
                   width="150"
                   style="display:block;" />
            </td>
          </tr>


          <tr>
            <td style="background-color:#F9C63D; height:3px; font-size:0; line-height:0;">&nbsp;</td>
          </tr>

          
          <tr>
            <td style="padding: 36px 40px;">

              <p style="margin:0 0 6px 0; font-size:20px; font-weight:700; color:#363D59;">
                Dear $userName,
              </p>
              <p style="margin:0 0 28px 0; font-size:14px; color:#555555; line-height:1.7;">
                We have received your account opening request at <strong>PayFX Global</strong>. 
                Please find the details of your submission below. Our team will review your 
                documents and reach out to you within 1–2 business days.
              </p>

              <!-- Section Label -->
              <p style="margin:0 0 10px 0; font-size:11px; font-weight:700; color:#F9C63D; 
                         text-transform:uppercase; letter-spacing:1.2px;">
                Submission Summary
              </p>

              <!-- Details Table -->
              <table width="100%" cellpadding="0" cellspacing="0" 
                     style="border-collapse:collapse; border: 1px solid #e0e0e0;">

                <tr>
                  <td style="padding:12px 16px; font-size:13px; color:#888888; 
                              background-color:#fafafa; width:40%;
                              border-bottom:1px solid #e0e0e0;">Full Name</td>
                  <td style="padding:12px 16px; font-size:13px; color:#363D59; 
                              font-weight:600; background-color:#fafafa;
                              border-bottom:1px solid #e0e0e0;">$userName</td>
                </tr>

                <tr>
                  <td style="padding:12px 16px; font-size:13px; color:#888888;
                              border-bottom:1px solid #e0e0e0;">Phone</td>
                  <td style="padding:12px 16px; font-size:13px; color:#363D59; 
                              font-weight:600;
                              border-bottom:1px solid #e0e0e0;">$userPhone</td>
                </tr>

                <tr>
                  <td style="padding:12px 16px; font-size:13px; color:#888888; 
                              background-color:#fafafa;
                              border-bottom:1px solid #e0e0e0;">Email</td>
                  <td style="padding:12px 16px; font-size:13px; color:#363D59; 
                              font-weight:600; background-color:#fafafa;
                              border-bottom:1px solid #e0e0e0;">$userEmail</td>
                </tr>

                <tr>
                  <td style="padding:12px 16px; font-size:13px; color:#888888;
                              border-bottom:1px solid #e0e0e0;">Account Type</td>
                  <td style="padding:12px 16px; font-size:13px; color:#363D59; 
                              font-weight:600;
                              border-bottom:1px solid #e0e0e0;">$_selectedAccountType</td>
                </tr>

                <tr>
                  <td style="padding:12px 16px; font-size:13px; color:#888888; 
                              background-color:#fafafa;
                              border-bottom:1px solid #e0e0e0;">Selected Provider</td>
                  <td style="padding:12px 16px; font-size:13px; color:#363D59; 
                              font-weight:600; background-color:#fafafa;
                              border-bottom:1px solid #e0e0e0;">$bankName</td>
                </tr>


                <tr>
                  <td style="padding:14px 16px; font-size:13px; color:#ffffff; 
                              font-weight:600; background-color:#363D59;">
                    Transaction Volume
                  </td>
                  <td style="padding:14px 16px; font-size:15px; color:#F9C63D; 
                              font-weight:700; background-color:#363D59;">
                    $amount
                  </td>
                </tr>

              </table>

             
              <p style="margin:28px 0 0 0; font-size:13px; color:#777777; line-height:1.7;
                         border-top:1px solid #eeeeee; padding-top:20px;">
                If you have any questions regarding your request, please contact us at 
                <a href="mailto:care@payfxglobal.com" 
                   style="color:#F9C63D; text-decoration:none;">
                  care@payfxglobal.com
                </a>.
              </p>

              <p style="margin:20px 0 0 0; font-size:13px; color:#363D59; line-height:1.7;">
                Warm regards,<br/>
                <strong>PayFX Global Support Team</strong>
              </p>

            </td>
          </tr>


          <tr>
            <td style="background-color:#F9C63D; height:3px; font-size:0; line-height:0;">&nbsp;</td>
          </tr>

         
          <tr>
            <td style="background-color:#363D59; padding: 20px 40px; text-align:center;">
              <p style="margin:0 0 4px 0; font-size:12px; color:#aaaaaa;">
                © 2026 PayFX Global. All rights reserved.
              </p>
              <p style="margin:0; font-size:11px; color:#666666;">
                This is an automated message. Please do not reply to this email.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>

</body>
</html>
""";


    print(htmlBody);

    final payload = {
      "from": {"address": "care@payfxglobal.com", "name": "Payfx Global Support"},
      "to": [
        {
          "email_address": {"address": userEmail, "name": userName}
        }
      ],

      "cc": [
        {
          "email_address": {
            "address": "care@payfxglobal.com",
            "name": "Support Team"
          }
        }
      ],
      "subject": "Account Opening Request - $bankName",
      "htmlbody": htmlBody,
    };



    try {
      final response = await dio.post(
        url,
        data: payload,
        options: Options(
          headers: {
            "accept": "application/json",
            "authorization": "Zoho-enczapikey $apiKey",
            "content-type": "application/json",
          },
        ),
      );

      debugPrint("Email API Response: ${response.data}");

      print(payload);
    } catch (e) {
      debugPrint("Email API Error: $e");
    }
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (offer_letter == null || front_passport == null || back_passport == null) {
      AppSnackbar.show(context, 'Please upload all required documents', success: false);
      return;
    }

    if (_selectedBank == null) {
      AppSnackbar.show(context, 'Please select a bank', success: false);
      return;
    }


    AppSnackbar.show(context, 'Submitting request...');


    await _sendEmailNotification();

    AppSnackbar.show(context, 'Request submitted successfully');

    Future.delayed(const Duration(milliseconds: 500), () {
      _resetForm();
    });
  }


  void _showScaffold() {
    if (_selectedAccountType == 'Blocked Account') {
      if (_selectedBank != 'Studley') {
        AppSnackbar.show(context, 'Select Studley and get more offers\n\n*Save Eur 179\n*Customer call center available in India', success: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0.0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.TextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Account Opening',
          style: TextStyle(
            color: AppColors.TextColor,
            fontSize: 20,
            fontWeight: FontWeight.w500,
            fontFamily: 'Satoshi',
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Account Type',
                  style: TextStyle(
                    color: AppColors.TextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Satoshi',
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _buildRadioOption('GIC', _selectedAccountType == 'GIC', () {
                      setState(() {
                        _selectedAccountType = 'GIC';
                        _selectedBank = null;
                        _showBill = false;
                        _selectedBankDetails = null;
                      });
                    }),
                    const SizedBox(width: 24),
                    _buildRadioOption(
                      'Blocked Account',
                      _selectedAccountType == 'Blocked Account',
                      () {
                        setState(() {
                          _selectedAccountType = 'Blocked Account';
                          _selectedBank = null;
                          _showBill = false;
                          _selectedBankDetails = null;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                AppTextField(
                  controller: _nameController,
                  labelText: 'Enter your name',
                  isRequired: true,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _emailController,
                  labelText: 'Enter your email',
                  isRequired: true,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _phoneController,
                  labelText: 'Enter your phone number',
                  isRequired: true,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Phone number is required';
                    }
                    if (value.length != 10) {
                      return 'Please enter a valid 10-digit number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                GestureDetector(
                  onTap: () => pickFile('offer'),
                  child: documentContainer(
                    'Upload Offer Letter',
                    isChecked: offer_letter != null,
                    fileName: offer_letter?.path.split('/').last,
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => pickFile('front'),
                  child: documentContainer(
                    'Upload your passport front page',
                    isChecked: front_passport != null,
                    fileName: front_passport?.path.split('/').last,
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => pickFile('back'),
                  child: documentContainer(
                    'Upload your passport back page',
                    isChecked: back_passport != null,
                    fileName: back_passport?.path.split('/').last,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Select Bank',
                  style: TextStyle(
                    color: AppColors.TextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Satoshi',
                  ),
                ),
                const SizedBox(height: 16),
                _buildBankListView(),
                if (_showBill && _selectedBankDetails != null) ...[
                  const SizedBox(height: 30),
                  _buildBillingSummary(),
                ],
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.PrimaryColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                        side: BorderSide(color: AppColors.PrimaryColor!, width: 2),
                      ),
                    ),
                    child: const Text(
                      'Submit Request',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Satoshi',
                        fontWeight: FontWeight.w500,
                        color: AppColors.TextColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBankListView() {
    final banks = _bankData[_selectedAccountType]!;
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: banks.length,
      itemBuilder: (context, index) {
        String bankName = banks.keys.elementAt(index);
        var details = banks[bankName]!;
        bool isSelected = _selectedBank == bankName;
        bool isRecommended = details['recommended'] ?? false;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedBank = bankName;
              _selectedBankDetails = details;
              _showBill = true;
              _showScaffold();
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.PrimaryColor : Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            bankName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? AppColors.TextColor : Colors.grey[800],
                              fontFamily: 'Satoshi',
                            ),
                          ),
                          if (isRecommended) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Recommended',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.PrimaryColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${details['currency']} ${details['amount']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontFamily: 'Satoshi',
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.PrimaryColor,
                  )
                else
                  Icon(
                    Icons.circle_outlined,
                    color: Colors.grey[300],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBillingSummary() {
    final amount = _selectedBankDetails!['amount'];
    final currency = _selectedBankDetails!['currency'];
    final isRecommended = _selectedBankDetails!['recommended'] ?? false;
    final details = _selectedBankDetails!['details'] ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.PrimaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Offer Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.TextColor,
                  fontFamily: 'Satoshi',
                ),
              ),
              if (isRecommended)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Recommended',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.PrimaryColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBillRow('Account Type', _selectedAccountType),
          const SizedBox(height: 10),
          _buildBillRow('Provider', '$_selectedBank'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(thickness: 1),
          ),
          _buildBillRow('Transaction Volume', '$currency $amount', isTotal: true),
          if (isRecommended && details.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                details,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.TextColor,
                  fontFamily: 'Satoshi',
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBillRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.TextColor,
            fontFamily: 'Satoshi',
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isTotal ? AppColors.PrimaryColor : AppColors.TextColor,
            fontFamily: 'Satoshi',
          ),
        ),
      ],
    );
  }

  Widget _buildRadioOption(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.PrimaryColor : Colors.grey[400]!,
                width: 2,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.PrimaryColor,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Satoshi',
              fontWeight: FontWeight.w500,
              color: isSelected ? AppColors.TextColor : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget documentContainer(String title, {bool isChecked = false, String? fileName}) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isChecked ? AppColors.PrimaryColor : AppColors.TextColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.upload_file_rounded, color: AppColors.TextColor, size: 25),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, color: AppColors.TextColor)),
                if (fileName != null)
                  Text(
                    fileName,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle_sharp,
            size: 25,
            color: isChecked ? Colors.green : Colors.grey,
          ),
        ],
      ),
    );
  }
}
