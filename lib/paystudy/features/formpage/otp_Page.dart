import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:payfxglobal/paystudy/core/constants/app_colors.dart';
import 'package:payfxglobal/paystudy/core/network/api_service.dart';
import 'package:payfxglobal/paystudy/features/loanOption/loan_OptionsPage.dart';
import 'package:payfxglobal/paystudy/model/LoanSubmitModel/loan_applicationdata.dart';
import 'package:payfxglobal/paystudy/core/constants/app_snackbar.dart';

class OTPFormPage extends StatefulWidget {
  const OTPFormPage({Key? key}) : super(key: key);

  @override
  State<OTPFormPage> createState() => _OTPFormPageState();
}

class _OTPFormPageState extends State<OTPFormPage>
    with TickerProviderStateMixin {

  static const int _otpLength = 5;
  final List<TextEditingController> _otpControllers =
  List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
  List.generate(_otpLength, (_) => FocusNode());


  final _storage = const FlutterSecureStorage();
  final ApiService _apiService = ApiService();
  final formData = LoanApplicationdata();
  final TextEditingController _newNumberCtrl = TextEditingController();

  String? _phone;
  bool _isLoading = false;
  bool _showChangeNumber = false;


  Timer? _resendTimer;
  int _resendSeconds = 30;
  bool _canResend = false;


  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  late AnimationController _cardCtrl;
  late Animation<double> _cardAnim;
  late AnimationController _changeCtrl;
  late Animation<double> _changeAnim;


  int get _filledCount =>
      _otpControllers.where((c) => c.text.isNotEmpty).length;

  @override
  void initState() {
    super.initState();


    _cardCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _cardAnim =
        CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic);
    _cardCtrl.forward();


    _shakeCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(_shakeCtrl);


    _changeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _changeAnim =
        CurvedAnimation(parent: _changeCtrl, curve: Curves.easeInOut);

    _loadPhone();
    _startResendTimer();


    for (final c in _otpControllers) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _newNumberCtrl.dispose();
    _shakeCtrl.dispose();
    _cardCtrl.dispose();
    _changeCtrl.dispose();
    super.dispose();
  }



  Future<void> _loadPhone() async {
    final stored = await _storage.read(key: 'studentNumber');
    if (mounted) setState(() => _phone = stored);
  }

  void _startResendTimer() {
    _resendSeconds = 30;
    _canResend = false;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_resendSeconds > 1) {
          _resendSeconds--;
        } else {
          _resendSeconds = 0;
          _canResend = true;
          t.cancel();
        }
      });
    });
  }

  void _triggerShake() {
    _shakeCtrl.reset();
    _shakeCtrl.forward();
  }

  void _toggleChangeNumber() {
    setState(() => _showChangeNumber = !_showChangeNumber);
    if (_showChangeNumber) {
      _changeCtrl.forward();
    } else {
      _changeCtrl.reverse();
    }
  }




  Future<void> _sendOtp() async {
    final id = await _storage.read(key: 'applicant_id');
    if (id == null) return;
    try {
      final res = await _apiService.post(
        'home/v1/api/sendotp',
        data: FormData.fromMap({'applicant_id': id}),
      );
      dynamic data = res.data;
      if (data is String) data = jsonDecode(data);
      print('sendOtp: $data');
      if (data['status'] == 'success') {

        AppSnackbar.show(context, 'OTP sent successfully');
        _startResendTimer();
      } else {

        AppSnackbar.show(context, 'Failed to send OTP', success: false);
      }
    } catch (e) {
      debugPrint('sendOtp error: $e');
    }
  }

  Future<void> _changePhoneNumber() async {
    final id = await _storage.read(key: 'applicant_id');
    try {
      final res = await _apiService.post(
        'home/v1/api/edit_mail_phone/phone',
        data: FormData.fromMap(
            {'otp_applicant_id': id, 'newPhoneNumber': _newNumberCtrl.text}),
      );
      dynamic data = res.data;
      if (data is String) data = jsonDecode(data);
      if (data['status'] == 'success') {
        setState(() {
          formData.phone = _newNumberCtrl.text;
          _phone = _newNumberCtrl.text;
          _showChangeNumber = false;
        });
        _changeCtrl.reverse();

        AppSnackbar.show(context, 'Phone number updated');
      } else {

        AppSnackbar.show(context, data['message'] ?? 'Invalid number', success: false);
      }
    } catch (e) {
      debugPrint('changePhone error: $e');
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < _otpLength) {
      _triggerShake();

      AppSnackbar.show(context, 'Please enter the complete 5-digit OTP', success: false);
      return;
    }
    final id = await _storage.read(key: 'applicant_id');
    setState(() => _isLoading = true);
    try {
      final res = await _apiService.post(
        'home/v1/api/otp_validation/phone',
        data: FormData.fromMap({'otp_applicant_id': id, 'phone_otp': otp}),
      );
      dynamic data = res.data;
      if (data is String) data = jsonDecode(data);
      if (data['status'] == 'success') {

        AppSnackbar.show(context, 'OTP verified!');
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => LoanOptionspage()),
                (route) => false,
          );
        }
      } else {

        AppSnackbar.show(context, data['message'] ?? 'Invalid OTP', success: false);
      }
    } catch (e) {
      debugPrint('verifyOtp error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'OTP Verification',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontSize: 18,
            fontWeight: FontWeight.w500,
            fontFamily: 'Satoshi',
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [

          SafeArea(
            child: FadeTransition(
              opacity: _cardAnim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.06),
                  end: Offset.zero,
                ).animate(_cardAnim),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Column(
                    children: [
                      _buildCard(),
                      const SizedBox(height: 20),
                      _buildVerifyButton(),
                      const SizedBox(height: 16),
                      Text(
                        'By verifying, you agree to our Terms of Service',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.PrimaryColor,
                  strokeWidth: 3,
                ),
              ),
            ),
        ],
      ),
    );
  }



  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.07),
            blurRadius: 40,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.lock_outline_rounded,
                color: AppColors.PrimaryColor, size: 30),
          ),
          const SizedBox(height: 20),


          const Text(
            'Verify your number',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A2E),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'We sent a 5-digit code to',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 14,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 8),

          // Phone row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '+91 ${_phone ?? ""}',
                style: const TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A2E),
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _toggleChangeNumber,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _showChangeNumber ? 'Cancel' : 'Change',
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
          const SizedBox(height: 24),

          // Change number panel
          SizeTransition(
            sizeFactor: _changeAnim,
            child: FadeTransition(
              opacity: _changeAnim,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
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
                            child: const Text(
                              '+91',
                              style: TextStyle(
                                fontFamily: 'Satoshi',
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                          Container(
                              width: 1,
                              color: const Color(0xFFE5E7EB)),
                          Expanded(
                            child: TextField(
                              cursorColor: AppColors.PrimaryColor,
                              controller: _newNumberCtrl,
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              decoration: const InputDecoration(
                                counterText: '',
                                hintText: 'Enter new number',
                                focusColor: AppColors.PrimaryColor,
                                hintStyle: TextStyle(
                                    color: Color(0xFFD1D5DB), fontSize: 13),
                                border: InputBorder.none,
                                contentPadding:
                                EdgeInsets.symmetric(horizontal: 12),
                              ),
                              style: const TextStyle(
                                fontFamily: 'Satoshi',
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _changePhoneNumber,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16),
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
                  ],
                ),
              ),
            ),
          ),


          AnimatedBuilder(
            animation: _shakeAnim,
            builder: (_, child) {
              final offset = _shakeCtrl.isAnimating
                  ? 8 *
                  (0.5 - (_shakeAnim.value - 0.5).abs()) *
                  ((_shakeAnim.value * 8).round().isEven ? 1 : -1)
                  : 0.0;
              return Transform.translate(
                  offset: Offset(offset, 0), child: child);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:
              List.generate(_otpLength, (i) => _buildOtpBox(i)),
            ),
          ),
          const SizedBox(height: 20),


          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: _filledCount / _otpLength,
              minHeight: 4,
              backgroundColor: const Color(0xFFF3F4F6),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.PrimaryColor,
              ),
            ),
          ),
          const SizedBox(height: 20),


          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Didn't receive it? ",
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
              ),
              GestureDetector(
                onTap: _canResend ? _sendOtp : null,
                child: _canResend
                    ? const Text(
                  'Resend OTP',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.PrimaryColor,
                    decoration: TextDecoration.underline,
                  ),
                )
                    : RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        fontFamily: 'Satoshi', fontSize: 13),
                    children: [
                      TextSpan(
                        text: 'Resend in ',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                      TextSpan(
                        text: '${_resendSeconds}s',
                        style: const TextStyle(
                          color: AppColors.PrimaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    final isFilled = _otpControllers[index].text.isNotEmpty;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 50,
      height: 60,
      decoration: BoxDecoration(
        color: isFilled ? const Color(0xFFEEF2FF) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFilled ?  AppColors.PrimaryColor : const Color(0xFFE5E7EB),
          width: 1,

        ),

      ),
      child: TextField(
        cursorColor: AppColors.PrimaryColor,
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        maxLength: 1,
        textAlign: TextAlign.center,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1A1A2E),
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
        ),
        onChanged: (val) {
          if (val.isNotEmpty && index < _otpLength - 1) {
            _focusNodes[index + 1].requestFocus();
          } else if (val.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }

  Widget _buildVerifyButton() {
    final ready = _filledCount == _otpLength;
    return AnimatedOpacity(
      opacity: ready ? 1.0 : 0.6,
      duration: const Duration(milliseconds: 200),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),

          ),
          child: ElevatedButton(
            onPressed: ready ? _verifyOtp : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.PrimaryColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: BorderSide(
                    color: AppColors.PrimaryColor!, width: 2),
              ),
            ),
            child: const Text(
              'Verify OTP',
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'Satoshi',
                fontWeight: FontWeight.w500,
                color: AppColors.TextColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}