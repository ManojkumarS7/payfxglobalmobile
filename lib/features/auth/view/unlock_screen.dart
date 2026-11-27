import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:payfxglobal/utils/user_storage.dart';
import 'package:payfxglobal/widgets/custom_loading_indicator.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/session_manager.dart';

class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key});
  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool isLoading = false;
  bool? _isResuming;
  int _failedAttempts = 0;

  static const Color _ink = Color(0xFF0B1B3A);
  static const Color _accent = Color(0xFFFFC72C);
  static const Color _bg = Color(0xFFF5F7FB);
  static const String _font = 'Satoshi';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _authenticate();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isResuming == null) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _isResuming = args?['isResuming'] as bool? ?? false;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _authenticate() async {
    if (isLoading) return;
    try {
      setState(() => isLoading = true);
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();
      if (!canAuthenticate) {
        await _handleSuccess();
        return;
      }
      final bool authenticated = await auth.authenticate(
        localizedReason: 'Unlock PayFX Global to continue',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      if (authenticated && mounted) {
        await _handleSuccess();
      } else if (!authenticated) {
        _failedAttempts++;
        if (_failedAttempts >= 5) {
          await SessionManager().forceLogout(reason: 'Too many failed attempts');
        }
      }
    } on PlatformException catch (_) {
    } catch (_) {
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _handleSuccess() async {
    await SessionManager.updateLastActive();
    if (!mounted) return;
    if (_isResuming == true) {
      Navigator.of(context).pop();
    } else {
      final userData = await UserStorage.getUserData();
      if (mounted) await _navigateToCorrectStepColdStart(context, userData);
    }
  }

  Future<void> _navigateToCorrectStepColdStart(BuildContext context, Map<String, dynamic> userData) async {
    if (userData.isEmpty) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      return;
    }
    final customerData = userData['customer'] is Map
        ? Map<String, dynamic>.from(userData['customer'])
        : (userData.containsKey('id') ? Map<String, dynamic>.from(userData) : <String, dynamic>{});
    final stepNo = int.tryParse(customerData['step_no']?.toString() ?? '0') ?? 0;
    final userId = customerData['id'];
    final email = customerData['email'];

    if (stepNo == 100) {
      Navigator.pushNamedAndRemoveUntil(context, '/identity-verification', (route) => false, arguments: {'user_id': userId, 'email': email, 'service': 'money_transfer'});
    } else if (stepNo == 200) {
      Map<String, dynamic> senderArgs = {'user_id': userId, 'email': email, 'service': 'money_transfer'};
      try {
        final panResponseRaw = customerData['pan_response'];
        if (panResponseRaw != null && panResponseRaw.toString().isNotEmpty) {
          final panResponse = panResponseRaw is String ? jsonDecode(panResponseRaw) : panResponseRaw;
          final panResult = panResponse['result'];
          if (panResult != null) {
            senderArgs['name'] = panResult['user_full_name'];
            senderArgs['dob'] = panResult['user_dob'];
            senderArgs['aadhaar'] = panResult['masked_aadhaar'];
            senderArgs['aadhaar_linked'] = panResult['aadhaar_linked_status'] == true || panResult['aadhaar_linked_status'] == 1 || panResult['aadhaar_linked_status'].toString() == 'true';
            final addr = panResult['user_address'];
            if (addr != null) senderArgs['address'] = {'street': addr['street_name'] ?? addr['line_1'] ?? '', 'line2': addr['line_2'] ?? '', 'city': addr['city'] ?? '', 'state': addr['state'] ?? '', 'pincode': addr['zip'] ?? ''};
          }
        }
      } catch (_) {}
      Navigator.pushNamedAndRemoveUntil(context, '/sender-details', (route) => false, arguments: senderArgs);
    } else if (stepNo == 300) {
      Navigator.pushNamedAndRemoveUntil(context, '/upload-documents', (route) => false, arguments: {'user_id': userId, 'email': email});
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false, arguments: {'userData': userData});
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 60),
                _FadeSlide(
                  index: 0,
                  child: Center(
                    child: Image.asset('assets/images/payfx.png', height: 160, fit: BoxFit.contain, 
                        errorBuilder: (_, __, ___) => const Text('PayFX', style: TextStyle(fontFamily: _font, fontSize: 32, fontWeight: FontWeight.w900, color:  AppTheme.PrimaryColor))),
                  ),
                ),
                const Spacer(),
                _FadeSlide(
                  index: 1,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color:  AppTheme.PrimaryColor.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 10))]),
                    child: const Icon(Icons.lock_open_rounded, size: 64, color:  AppTheme.PrimaryColor),
                  ),
                ),
                const SizedBox(height: 40),
                _FadeSlide(index: 2, child: const Text('Locked App', style: TextStyle(fontFamily: _font, fontSize: 26, fontWeight: FontWeight.w900, color: _ink, letterSpacing: -0.5))),
                const SizedBox(height: 12),
                _FadeSlide(index: 3, child: const Text('Please authenticate to continue accessing your secure transfers.', textAlign: TextAlign.center, style: TextStyle(fontFamily: _font, fontSize: 15, color: Colors.grey, height: 1.5, fontWeight: FontWeight.w600))),
                const Spacer(),
                if (isLoading)
                  const _FadeSlide(index: 4, child: CustomLoadingIndicator())
                else
                  _FadeSlide(
                    index: 4,
                    child: _Pressable(
                      onTap: _authenticate,
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color:  AppTheme.PrimaryColor, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color:  AppTheme.PrimaryColor.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6))]),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.fingerprint_rounded, color: Colors.white, size: 24),
                            SizedBox(width: 12),
                            Text('CONTINUE', style: TextStyle(fontFamily: _font, fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                _FadeSlide(
                  index: 5,
                  child: TextButton(
                    onPressed: () async => await SessionManager().forceLogout(),
                    child: Text('Not you? Sign out', style: TextStyle(fontFamily: _font, color: Colors.grey.shade600, fontWeight: FontWeight.w800, decoration: TextDecoration.underline)),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FadeSlide extends StatelessWidget {
  final Widget child;
  final int index;
  const _FadeSlide({required this.child, this.index = 0});
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + index * 100),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, 30 * (1 - value)), child: child),
      ),
      child: child,
    );
  }
}

class _Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _Pressable({required this.child, this.onTap});
  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
