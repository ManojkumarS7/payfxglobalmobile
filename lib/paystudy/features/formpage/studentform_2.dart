import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payfxglobal/paystudy/core/constants/app_colors.dart';
import 'package:payfxglobal/paystudy/core/constants/app_dropfield.dart';
import 'package:payfxglobal/paystudy/core/constants/app_textfield.dart';
import 'package:payfxglobal/paystudy/core/constants/dashboard.dart';
import 'package:payfxglobal/paystudy/model/LoanSubmitModel/loan_applicationdata.dart';
import 'package:payfxglobal/paystudy/features/formpage/universityform.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:payfxglobal/paystudy/core/providers/second_student_form/second_form_provider.dart';
import 'package:payfxglobal/paystudy/features/home/home_dashboard.dart';
import 'package:payfxglobal/paystudy/core/base_url/base_url.dart';
import 'package:payfxglobal/paystudy/core/network/api_service.dart';
import 'package:payfxglobal/paystudy/core/constants/app_snackbar.dart';
import 'package:payfxglobal/widgets/custom_button.dart';

class SecondStudentForm extends ConsumerStatefulWidget {
  final LoanApplicationdata formData;
  const SecondStudentForm({super.key, required this.formData});

  @override
  ConsumerState<SecondStudentForm> createState() => _SecondStudentFormState();
}

class _SecondStudentFormState extends ConsumerState<SecondStudentForm> {
  final _formKey = GlobalKey<FormState>();
  final newNumber = TextEditingController();
  final ApiService _apiService = ApiService();

  bool _showNewNumberPopup = false;
  final _storage = const FlutterSecureStorage();

  final List<TextEditingController> _otpControllers = List.generate(
    5,
        (_) => TextEditingController(),
  );

  final Map<String, String> appliedCollegeMap = {
    'Applied, Waiting For Response': 'applied',
    'Shortlisted, But No Response': 'shortlisted',
    'Not Shortlisted, Not Applied': 'not_applied',
  };

  @override
  void dispose() {
    newNumber.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final state = ref.read(secondFormProvider);


    widget.formData.education_avilable = state.hasOfferLetter ? 'Yes' : 'No';


    if (!state.hasOfferLetter) {
      widget.formData.education_applied =
          appliedCollegeMap[state.appliedDetail] ?? '';


      if (state.appliedDetail == 'Not Shortlisted, Not Applied') {
        widget.formData.decided_course =
        state.targetCourse == true ? 'Yes' : 'No';
        widget.formData.decided_country =
        state.targetCountry == true ? 'Yes' : 'No';
      } else {

        widget.formData.decided_course = '';
        widget.formData.decided_country = '';
      }
    } else {

      widget.formData.education_applied = '';
      widget.formData.decided_course = '';
      widget.formData.decided_country = '';
    }

    try {
      final body = widget.formData.toApiBody();

      final applicationid =
      await _storage.read(key: 'applicant_id');

      if (applicationid != null) {
        body['applicant_id'] = applicationid;
      }


      final response = await _apiService.post(
        'home/v1/api/loan_eligible_store',
        data: FormData.fromMap(body),
      );

      debugPrint('STATUS: ${response.statusCode}');
      debugPrint('BODY: ${response.data}');


      dynamic responseData = response.data;

      if (responseData is String) {
        responseData = jsonDecode(responseData);
      }

      if (response.statusCode == 200 &&
          responseData['status'] == 'success') {

        final String? appId =
        responseData['applicant_id']?.toString();

        if (appId != null) {
          await _storage.write(key: 'applicant_id', value: appId);
          widget.formData.application_id = appId;
        }


        Future.delayed(const Duration(milliseconds: 100), () {
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (_) =>
                  UniversityFormPage(formData: widget.formData),
            ),
          );
        });
      }

    } catch (e) {
      debugPrint('Submit Error: $e');
    }
  }



  Future<void> sendOtp() async {
    final applicationid = await _storage.read(key: 'applicant_id');

    if (applicationid == null) {
      debugPrint('applicationid is empty');
      return;
    }

    try {
      final response = await _apiService.post(
        'home/v1/api/sendotp',
        data: FormData.fromMap({
          'applicant_id': applicationid,
        }),
      );

      dynamic data = response.data;


      if (data is String) {
        data = jsonDecode(data);
      }

      if (data['status'] == 'success') {

        AppSnackbar.show(context, 'OTP sent successfully');

      } else {
        AppSnackbar.show(context, 'Failed to send OTP', success: false);
      }
    } catch (e) {
      debugPrint('Send OTP error: $e');
    }
  }

  Future<void> otpVerify() async {
    final applicationid = await _storage.read(key: 'applicant_id');
    final otp = _otpControllers.map((c) => c.text).join();

    if (otp.length < 5) {
      AppSnackbar.show(context, 'Please enter 5 digit OTP', success: false);
      return;
    }

    try {
      final response = await _apiService.post(
        'home/v1/api/otp_validation/phone',
        data: FormData.fromMap({
          'otp_applicant_id': applicationid,
          'phone_otp': otp,
        }),
      );

      dynamic data = response.data;

      if (data is String) {
        data = jsonDecode(data);
      }

      if (data['status'] == 'success') {

        ref.read(secondFormProvider.notifier).showOtp(false);

    AppSnackbar.show(context,'OTP verified successfully');

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainDashboard()),
                (route) => false,
          );
        }

      } else {

        AppSnackbar.show(context, 'Invalid OTP', success: false);
      }
    } catch (e) {
      debugPrint('OTP verify error: $e');
    }
  }

  Future<void> changePhoneNumber() async {
    final applicationid = await _storage.read(key: 'applicant_id');

    try {
      final response = await _apiService.post(
        'home/v1/api/edit_mail_phone/phone',
        data: FormData.fromMap({
          'otp_applicant_id': applicationid,
          'newPhoneNumber': newNumber.text,
        }),
      );

      dynamic data = response.data;

      if (data is String) {
        data = jsonDecode(data);
      }

      if (data['status'] == 'success') {
        
        setState(() {
          widget.formData.phone = newNumber.text;
        });

 AppSnackbar.show(context, 'New number updated successfully');

      } else {
        AppSnackbar.show(context, 'Invalid number', success: false);
      }
    } catch (e) {
      debugPrint('Change phone error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentFormState = ref.watch(secondFormProvider);
    final notifier = ref.read(secondFormProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0.0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.TextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Check Eligibility',
          style: TextStyle(
            color: AppColors.TextColor,
            fontSize: 20,
            fontWeight: FontWeight.w500,
            fontFamily: 'Satoshi',
          ),
        ),
      ),
      body: Stack(
        children: [

          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [


                    const Text(
                      'Do you have an offer letter?',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildRadioOption(
                          'Yes',
                          studentFormState.hasOfferLetter,
                              () => notifier.toggleOfferLetter(true),
                        ),
                        const SizedBox(width: 24),
                        _buildRadioOption(
                          'No',
                          !studentFormState.hasOfferLetter,
                              () => notifier.toggleOfferLetter(false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),


                    if (!studentFormState.hasOfferLetter) ...[
                      AppDropdownField(
                        labelText: 'Have you applied to any colleges?',
                        hintText: 'Have you applied to any colleges?',
                        value: studentFormState.appliedDetail,
                        items: const [
                          'Applied, Waiting For Response',
                          'Shortlisted, But No Response',
                          'Not Shortlisted, Not Applied',
                        ],
                        onChanged: (value) {
                          if (value != null) notifier.setAppliedDetail(value);
                        },
                      ),
                      const SizedBox(height: 30),
                    ],


                    if (!studentFormState.hasOfferLetter &&
                        studentFormState.appliedDetail ==
                            'Not Shortlisted, Not Applied') ...[
                      const Text(
                        'Have you decided your target course?',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildRadioOption(
                            'Yes',
                            studentFormState.targetCourse == true,
                                () => notifier.setTargetCourse(true),
                          ),
                          const SizedBox(width: 24),
                          _buildRadioOption(
                            'No',
                            studentFormState.targetCourse == false,
                                () {
                              notifier.setTargetCourse(false);
                              _showCallbackPopup(); // show OTP popup
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                    ],


                    if (!studentFormState.hasOfferLetter &&
                        studentFormState.appliedDetail ==
                            'Not Shortlisted, Not Applied' &&
                        studentFormState.targetCourse == true) ...[
                      const Text(
                        'Have you decided your target country?',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildRadioOption(
                            'Yes',
                            studentFormState.targetCountry == true,
                                () => notifier.setTargetCountry(true),
                          ),
                          const SizedBox(width: 24),
                          _buildRadioOption(
                            'No',
                            studentFormState.targetCountry == false,
                                () => notifier.setTargetCountry(false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                    ],

                    const SizedBox(height: 100),


                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.PrimaryColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                            side: BorderSide(
                              color: AppColors.PrimaryColor!,
                              width: 2,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Next',
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'Satoshi',
                            fontWeight: FontWeight.w500,
                            color: AppColors.TextColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),


          if (studentFormState.showOtpPopup == true)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.PrimaryColor.withOpacity(0.12),
                        blurRadius: 40,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.PrimaryColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.lock_outline_rounded,
                                color: AppColors.PrimaryColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'OTP Verification',
                                    style: TextStyle(
                                      color: AppColors.TextColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Satoshi',
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Enter the code sent to your number',
                                    style: TextStyle(
                                      color: Color(0xFF9CA3AF),
                                      fontSize: 12,
                                      fontFamily: 'Satoshi',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => notifier.showOtp(false),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.phone_outlined,
                                size: 18,
                                color: Color(0xFF9CA3AF),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '+91 ${widget.formData.phone}',
                                style: const TextStyle(
                                  color: AppColors.TextColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Satoshi',
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _showNewNumberPopup = !_showNewNumberPopup),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.PrimaryColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _showNewNumberPopup ? 'Cancel' : 'Change',
                                    style: const TextStyle(
                                      fontFamily: 'Satoshi',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.PrimaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),


                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 280),
                          crossFadeState: _showNewNumberPopup
                              ? CrossFadeState.showFirst
                              : CrossFadeState.showSecond,
                          firstChild: Column(
                            children: [

                              Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding:
                                      const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF3F4F6),
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(13),
                                          bottomLeft: Radius.circular(13),
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text(
                                        '+91',
                                        style: TextStyle(
                                          fontFamily: 'Satoshi',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ),
                                    Container(width: 1, color: const Color(0xFFE5E7EB)),
                                    Expanded(
                                      child: TextField(
                                        controller: newNumber,
                                        keyboardType: TextInputType.phone,
                                        maxLength: 10,
                                        decoration: const InputDecoration(
                                          counterText: '',
                                          hintText: 'Enter new number',
                                          hintStyle: TextStyle(
                                              color: Color(0xFFD1D5DB), fontSize: 13),
                                          border: InputBorder.none,
                                          contentPadding:
                                          EdgeInsets.symmetric(horizontal: 12),
                                        ),
                                        style: const TextStyle(
                                          fontFamily: 'Satoshi',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.TextColor,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() => _showNewNumberPopup = false);
                                        changePhoneNumber();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        height: 52,
                                        decoration: const BoxDecoration(
                                          color: AppColors.PrimaryColor,
                                          borderRadius: BorderRadius.only(
                                            topRight: Radius.circular(13),
                                            bottomRight: Radius.circular(13),
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: const Text(
                                          'Update',
                                          style: TextStyle(
                                            fontFamily: 'Satoshi',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                          secondChild: const SizedBox.shrink(),
                        ),


                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(5, (index) => _otpBox(index)),
                        ),
                        const SizedBox(height: 16),


                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: _otpControllers.where((c) => c.text.isNotEmpty).length / 5,
                            minHeight: 4,
                            backgroundColor: const Color(0xFFF3F4F6),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.PrimaryColor),
                          ),
                        ),
                        const SizedBox(height: 28),

                        AppPrimaryButton(title: 'Verify OTP', onPressed: otpVerify),


                        // SizedBox(
                        //   width: double.infinity,
                        //   height: 50,
                        //   child: DecoratedBox(
                        //     decoration: BoxDecoration(
                        //
                        //       borderRadius: BorderRadius.circular(16),
                        //       border: Border.all(
                        //         color: AppColors.PrimaryColor
                        //       )
                        //
                        //     ),
                        //     child: ElevatedButton(
                        //       onPressed: otpVerify,
                        //       style: ElevatedButton.styleFrom(
                        //         backgroundColor: Colors.transparent,
                        //         shadowColor: Colors.transparent,
                        //         shape: RoundedRectangleBorder(
                        //           borderRadius: BorderRadius.circular(16),
                        //         ),
                        //       ),
                        //       child: const Text(
                        //         'Verify OTP',
                        //         style: TextStyle(
                        //           fontFamily: 'Satoshi',
                        //           fontSize: 16,
                        //           fontWeight: FontWeight.w500,
                        //           color: AppColors.TextColor,
                        //           letterSpacing: 0.2,
                        //         ),
                        //       ),
                        //     ),
                        //   ),
                        // ),
                        const SizedBox(height: 20),


                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Didn't receive it? ",
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                fontSize: 13,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                            GestureDetector(
                              onTap: sendOtp,
                              child: const Text(
                                'Resend OTP',
                                style: TextStyle(
                                  fontFamily: 'Satoshi',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.PrimaryColor,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppColors.PrimaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }


  Widget _otpBox(int index) {
    return SizedBox(
      width: 50,
      height: 80,
      child: TextField(
        controller: _otpControllers[index],
        keyboardType: TextInputType.number,
        maxLength: 1,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: AppColors.TextColor,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.PrimaryColor),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 4) {
            FocusScope.of(context).nextFocus();
          }
        },
      ),
    );
  }


  Widget _buildRadioOption(
      String label, bool isSelected, VoidCallback onTap) {
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
                color: isSelected ? AppColors.PrimaryColor! : Colors.grey,
                width: 2,
              ),
            ),
            child: isSelected
                ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
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
              fontWeight: FontWeight.w500,
              color: isSelected ? AppColors.TextColor : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }


  void _showCallbackPopup() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Get a Callback',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppColors.TextColor,
          ),
        ),
        content: const Text(
          'You can check your loan eligibility once you\'ve shortlisted a course. '
              'We can help you get matched with the right admission consultant for free!',
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.TextColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              sendOtp();
              ref.read(secondFormProvider.notifier).showOtp(true);
            },
            child: const Text(
              'Verify',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.PrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
