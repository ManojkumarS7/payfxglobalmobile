import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:payfxglobal/utils/app_theme.dart';
import 'package:payfxglobal/widgets/no_internet_banner.dart';
import '../../services/app_services.dart';
import 'package:lottie/lottie.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  static const Color _ink = Color(0xFF0B1B3A);
  static const Color _bg = Colors.white;
  static const String _font = 'Satoshi';

  static const String _animationPath = 'assets/animations/global_remittance.json';
  late final Future<LottieComposition> _compositionFuture;
  late final AnimationController _lottieController;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
    // Pre-cache composition and start fast playback (2.0x speed) immediately
    _compositionFuture = AssetLottie(_animationPath).load().then((composition) {
      if (mounted) {
        _lottieController.duration = composition.duration * 0.5; // 2.0x playback speed
        _lottieController.repeat();
      }
      return composition;
    });
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: networkService.internetStatus,
      initialData: true,
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? true;

        if (!isConnected) {
          return NoInternetScreen(onRetry: () {});
        }

        return Scaffold(
          backgroundColor: _bg,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Available screen dimensions
                final screenHeight = constraints.maxHeight;
                final screenWidth = constraints.maxWidth;

                // Responsive animation height
                final animationHeight = math.min(
                  screenWidth * 9 / 16,
                  screenHeight * 0.28,
                ).clamp(100.0, 220.0);

                // Responsive spacing and padding
                final isSmallScreen = screenHeight < 650;

                final cardPadding = isSmallScreen ? 20.0 : 28.0;
                final topSpacing = isSmallScreen ? 6.0 : 12.0;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                        child: Column(
                          children: [
                            SizedBox(height: topSpacing),

                            // PayFX Logo
                            _FadeSlide(
                              index: 0,
                              child: Center(
                                child: Image.asset(
                                  'assets/images/payfx.png',
                                  height: isSmallScreen ? 85 : 100,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) {
                                    return const Text(
                                      'PayFX',
                                      style: TextStyle(
                                        fontFamily: _font,
                                        fontSize: 40,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.PrimaryColor,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                            SizedBox(height: isSmallScreen ? 5 : 8),

                            // Tagline
                            _FadeSlide(
                              index: 1,
                              child: const Text(
                                'Global Remittance & Finance',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: _font,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey,
                                ),
                              ),
                            ),

                            SizedBox(height: isSmallScreen ? 5 : 10),

                            // Global Animation - Immediate display with 2.0x playback speed
                            _buildGlobalAnimation(animationHeight),

                            // Flexible space
                            const Spacer(flex: 2),

                            // Welcome Card
                            _FadeSlide(
                              index: 2,
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(cardPadding),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(32),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.PrimaryColor
                                          .withOpacity(0.06),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Welcome to PayFX',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: _font,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        color: _ink,
                                        letterSpacing: -0.5,
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    Text(
                                      'Experience seamless international banking. '
                                          'Send money abroad, manage student accounts, '
                                          'and access education loans — all in one secure platform.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: _font,
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                        height: 1.6,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),

                                    SizedBox(
                                      height: isSmallScreen ? 22 : 32,
                                    ),

                                    // Get Started
                                    _Pressable(
                                      onTap: () {
                                        Navigator.of(context)
                                            .pushNamed('/email-entry');
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        height: 52,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: AppTheme.PrimaryColor,
                                          borderRadius:
                                          BorderRadius.circular(30),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppTheme.PrimaryColor
                                                  .withOpacity(0.2),
                                              blurRadius: 12,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: const Text(
                                          'Get Started',
                                          style: TextStyle(
                                            fontFamily: _font,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 18),

                                    // Login
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      crossAxisAlignment:
                                      WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          'Already have an account? ',
                                          style: TextStyle(
                                            fontFamily: _font,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.of(context)
                                                .pushNamed('/login');
                                          },
                                          child: const Text(
                                            'Login',
                                            style: TextStyle(
                                              fontFamily: _font,
                                              color: AppTheme.PrimaryColor,
                                              fontWeight: FontWeight.w900,
                                              decoration:
                                              TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const Spacer(flex: 1),

                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // Responsive Lottie animation with explicit AnimationController for fast (2.0x) playback
  Widget _buildGlobalAnimation(double height) {
    return SizedBox(
      height: 300,
      width: double.infinity,
      child: FutureBuilder<LottieComposition>(
        future: _compositionFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Lottie(
              composition: snapshot.data,
              controller: _lottieController,
              fit: BoxFit.contain,
              alignment: Alignment.center,
            );
          }
          return Lottie.asset(
            _animationPath,
            fit: BoxFit.contain,
            alignment: Alignment.center,
          );
        },
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
      duration: Duration(milliseconds: 450 + index * 90),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, 24 * (1 - value)), child: child),
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
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
