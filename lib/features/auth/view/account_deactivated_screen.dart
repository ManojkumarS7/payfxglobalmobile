import 'package:flutter/material.dart';
import '../../../utils/app_theme.dart';
import '../service/auth_api_service.dart';

/// Shown when the API returns {"status":"error","message":"Account Deactivated …"}
/// for any login / registration attempt.
///
/// The page tells the user their account is deactivated and that a verification
/// link has been (or will be) sent to their email.
class AccountDeactivatedScreen extends StatefulWidget {
  const AccountDeactivatedScreen({super.key});

  @override
  State<AccountDeactivatedScreen> createState() => _AccountDeactivatedScreenState();
}

class _AccountDeactivatedScreenState extends State<AccountDeactivatedScreen>
    with SingleTickerProviderStateMixin {
  // Colours & font — matched with the rest of the app
  static const Color _navy = AppTheme.PrimaryColor;
  static const Color _ink = Color(0xFF0B1B3A);
  static const Color _bg = Color(0xFFF5F7FB);
  static const String _font = 'Satoshi';

  late final AnimationController _pulse;
  late final Animation<double> _scale;

  String? _email;
  String? _errorMessage;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _email = args['email']?.toString();
      _errorMessage = args['message']?.toString();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    if (_email == null || _email!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email not found. Please try logging in again.")),
      );
      return;
    }

    setState(() => _isChecking = true);
    try {
      final response = await AuthApiService().checkAccountActivation(_email!);
      
      // Based on API: {"verified": true}
      if (response['verified'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Account activated please login and continue"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? "Account not yet verified. Please check your email."),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to check activation status. Please try again."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    int i = 0;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
      },
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: RefreshIndicator(
            color: _navy,
            onRefresh: _checkStatus,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // ── Animated lock / warning icon ─────────────────────────────
                  _FadeSlide(
                    index: i++,
                    child: Center(
                      child: ScaleTransition(
                        scale: _scale,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withValues(alpha: 0.2),
                                blurRadius: 30,
                                spreadRadius: 6,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.lock_person_rounded,
                            size: 56,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Headline ─────────────────────────────────────────────────
                  _FadeSlide(
                    index: i++,
                    child: const Text(
                      'Account Deactivated',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: _font,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: _ink,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Sub-headline ─────────────────────────────────────────────
                  _FadeSlide(
                    index: i++,
                    child: Text(
                      _errorMessage?.isNotEmpty == true
                          ? _errorMessage!
                          : 'Your account has been temporarily deactivated.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: _font,
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Info card ────────────────────────────────────────────────
                  _FadeSlide(
                    index: i++,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: _navy.withValues(alpha: 0.07),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Email chip
                          if (_email != null && _email!.isNotEmpty) ...[
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _navy.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.email_outlined, color: _navy, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Verification sent to',
                                        style: TextStyle(
                                          fontFamily: _font,
                                          fontSize: 11,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        _email!,
                                        style: const TextStyle(
                                          fontFamily: _font,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: _ink,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Divider(color: Colors.grey.shade100, height: 1),
                            const SizedBox(height: 20),
                          ],

                          // Step 1
                          _buildStep(
                            number: '1',
                            icon: Icons.mark_email_read_outlined,
                            title: 'Check your email',
                            body: 'We have sent a verification link to your registered email address.',
                          ),
                          const SizedBox(height: 16),

                          // Step 2
                          _buildStep(
                            number: '2',
                            icon: Icons.touch_app_rounded,
                            title: 'Click the verification link',
                            body: 'Open the email and click the "Activate Account" button inside.',
                          ),
                          const SizedBox(height: 16),

                          // Step 3
                          _buildStep(
                            number: '3',
                            icon: Icons.check_circle_outline_rounded,
                            title: 'You\'re all set',
                            body: 'After verification you\'ll be redirected back to the app and signed in automatically.',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Refresh / Check Status Button ────────────────────────────
                  _FadeSlide(
                    index: i++,
                    child: _Pressable(
                      onTap: _isChecking ? null : _checkStatus,
                      child: Container(
                        width: double.infinity,
                        height: 58,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.25),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: _isChecking
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text(
                                'I have verified my email',
                                style: TextStyle(
                                  fontFamily: _font,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Tip card ─────────────────────────────────────────────────
                  _FadeSlide(
                    index: i++,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber.shade200, width: 1),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded, color: Colors.amber.shade700, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Don\'t see the email? Check your spam/junk folder, or contact support at support@payfxglobal.com',
                              style: TextStyle(
                                fontFamily: _font,
                                fontSize: 13,
                                color: Colors.amber.shade800,
                                fontWeight: FontWeight.w600,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Back to Login button ─────────────────────────────────────
                  _FadeSlide(
                    index: i++,
                    child: _Pressable(
                      onTap: () =>
                          Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false),
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _navy,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: _navy.withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Back to Login',
                          style: TextStyle(
                            fontFamily: _font,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Contact support text link ────────────────────────────────
                  _FadeSlide(
                    index: i++,
                    child: Center(
                      child: TextButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/support'),
                        icon: const Icon(Icons.headset_mic_rounded, size: 16, color: _navy),
                        label: const Text(
                          'Contact Support',
                          style: TextStyle(
                            fontFamily: _font,
                            color: _navy,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
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
      ),
    );
  }

  // ── Helper Widgets ──────────────────────────────────────────────────────────

  Widget _buildStep({
    required String number,
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Numbered badge
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _navy.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontFamily: _font,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: _navy,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: _navy),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontFamily: _font,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Shared animation helpers (private to this file) ─────────────────────────

class _FadeSlide extends StatelessWidget {
  final Widget child;
  final int index;
  const _FadeSlide({required this.child, this.index = 0});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + index * 80),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, 22 * (1 - value)), child: child),
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
        scale: _down ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
