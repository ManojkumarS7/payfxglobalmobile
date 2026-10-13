import 'package:flutter/material.dart';
import 'package:payfxglobal/utils/app_theme.dart';
import 'package:payfxglobal/widgets/no_internet_banner.dart';
import '../../services/app_services.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  // ---- Palette (Matched with Dashboard) ----
  // static const Color _navy = Color(0xFF16305C);
  static const Color _ink = Color(0xFF0B1B3A);
  static const Color _accent = Color(0xFFFFC72C);
  static const Color _bg = Colors.white;
  static const String _font = 'Satoshi';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: networkService.internetStatus,
      initialData: true,
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? true;
        if (!isConnected) return NoInternetScreen(onRetry: () {});

        return Scaffold(
          backgroundColor: _bg,
          body: Stack(
            children: [
              // Background subtle overlay
              Positioned.fill(
                child: Opacity(
                  opacity: 0.05,
                  child: Image.asset('assets/images/Firefly.png', fit: BoxFit.cover),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      _FadeSlide(
                        index: 0,
                        child: Center(
                          child: Image.asset('assets/images/payfx.png', height: 180, fit: BoxFit.contain, 
                              errorBuilder: (_, __, ___) => const Text('PayFX', style: TextStyle(fontFamily: _font, fontSize: 40, fontWeight: FontWeight.w900, color: AppTheme.PrimaryColor))),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _FadeSlide(
                        index: 1,
                        child: const Text('Global Remittance & Finance', style: TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w700, color: Colors.grey)),
                      ),
                      const Spacer(flex: 3),
                      _FadeSlide(
                        index: 2,
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: AppTheme.PrimaryColor.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 10))]),
                          child: Column(
                            children: [
                              const Text('Welcome to PayFX', style: TextStyle(fontFamily: _font, fontSize: 24, fontWeight: FontWeight.w900, color: _ink, letterSpacing: -0.5)),
                              const SizedBox(height: 16),
                              Text(
                                'Experience seamless international banking. Send money abroad, manage student accounts, and access education loans — all in one secure platform.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontFamily: _font, fontSize: 14, color: Colors.grey.shade600, height: 1.6, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 32),
                              _Pressable(
                                onTap: () => Navigator.of(context).pushNamed('/email-entry'),
                                child: Container(
                                  width: double.infinity,
                                  height: 56,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(color: AppTheme.PrimaryColor, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: AppTheme.PrimaryColor.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6))]),
                                  child: const Text('Get Started', style: TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Already have an account? ', style: TextStyle(fontFamily: _font, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                                  GestureDetector(
                                    onTap: () => Navigator.of(context).pushNamed('/login'),
                                    child: const Text('Login', style: TextStyle(fontFamily: _font, color: AppTheme.PrimaryColor, fontWeight: FontWeight.w900, decoration: TextDecoration.underline)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(flex: 1),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
      duration: Duration(milliseconds: 600 + index * 150),
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
