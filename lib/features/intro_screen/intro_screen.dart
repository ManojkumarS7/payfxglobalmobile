import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/app_theme.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});
  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // ---- Palette (Matched with Dashboard) ----
  static const Color _navy =  AppTheme.PrimaryColor;
  static const Color _ink = Color(0xFF0B1B3A);
  static const Color _accent = Color(0xFFFFC72C);
  static const Color _bg = Color(0xFFF5F7FB);
  static const String _font = 'Satoshi';

  final List<Map<String, String>> _introData = [
    {
      'title': 'Global Remittance',
      'description': 'Send money across borders with ease. Fast, secure, and competitive exchange rates for all your global needs.',
      'image': 'assets/images/introglobal.png',
    },
    {
      'title': 'Education Loan',
      'description': 'Supporting your academic dreams with hassle-free loan assistance and documentation guidance for overseas study.',
      'image': 'assets/images/introedu.png',
    },
    {
      'title': 'Study Abroad Accounts',
      'description': 'Expert assistance for opening Blocked Accounts and GIC required for your international education journey.',
      'image': 'assets/images/introgic.png',
    },
  ];

  void _onFinish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_intro', true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/welcome');
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _introData.length - 1;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Background subtle pattern or image
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Image.asset('assets/images/Firefly.png', fit: BoxFit.cover),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Image.asset('assets/images/payfx.png', height: 40, fit: BoxFit.contain, 
                            errorBuilder: (_, __, ___) => const Text('PayFX', style: TextStyle(fontFamily: _font, fontSize: 20, fontWeight: FontWeight.w900, color: _navy))),
                      ),
                      TextButton(
                        onPressed: _onFinish,
                        child: const Text('Skip', style: TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w800, color: Colors.grey)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    itemCount: _introData.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _FadeSlide(
                              index: 0,
                              child: Container(
                                height: 280,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(32),
                                  boxShadow: [BoxShadow(color: _navy.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 10))],
                                ),
                                padding: const EdgeInsets.all(30),
                                child: Image.asset(_introData[index]['image']!, fit: BoxFit.contain),
                              ),
                            ),
                            const SizedBox(height: 50),
                            _FadeSlide(
                              index: 1,
                              child: Text(
                                _introData[index]['title']!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontFamily: _font, fontSize: 26, fontWeight: FontWeight.w900, color: _ink, letterSpacing: -0.5),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _FadeSlide(
                              index: 2,
                              child: Text(
                                _introData[index]['description']!,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontFamily: _font, fontSize: 15, color: Colors.grey.shade600, height: 1.6, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: List.generate(
                          _introData.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 8),
                            height: 6,
                            width: _currentPage == index ? 24 : 6,
                            decoration: BoxDecoration(
                              color: _currentPage == index ? _navy : Colors.grey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                      _Pressable(
                        onTap: () {
                          if (isLastPage) _onFinish();
                          else _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: _navy.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6))]),
                          child: Row(
                            children: [
                              Text(isLastPage ? 'Get Started' : 'Next', style: const TextStyle(fontFamily: _font, color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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
