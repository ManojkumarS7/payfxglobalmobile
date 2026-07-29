

import 'package:flutter/material.dart';
import 'package:payfxglobal/utils/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../paystudy/core/network/api_service.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});
  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pageController = PageController();

  int _currentPage = 0;
  final List<Map<String, String>> _introData = [
    {
      'title': 'Global Remittance',
      'description':
      'PayFX Global provides secure and reliable international remittance services for students, individuals, and businesses. We support fast cross-border money transfers with competitive exchange rates, transparent processing, and dedicated customer assistance for global payment needs',
      'image': 'assets/images/introglobal.png',
    },
    {
      'title': 'Education Loan',
      'description':
      'PayFX Global provides education loan assistance services by supporting students in identifying suitable financing options for overseas education. We assist with documentation guidance, application support, and coordination with financial institutions to simplify the loan process',
      'image': 'assets/images/introedu.png',
    },
    {
      'title': 'Blocked Account / GIC Account Opening Assitance',
      'description':
      'PayFX Global provides assistance for opening Blocked Accounts and Guaranteed Investment Certificate (GIC) accounts required for international education and visa purposes. We support students with account opening procedures, documentation requirements, and onboarding guidance for a smooth process.',
      'image': 'assets/images/introgic.png',
    },
  ];

  static const Color _navy = Color(0xFF16305C);

  void _onFinish() async {
    final prefs = await SharedPreferences.getInstance();
    // Fix: Write seen_intro as true to SharedPreferences
    await prefs.setBool('seen_intro', true);
    final seenIntro = prefs.getBool('seen_intro') ?? false;
    debugPrint('====================');
    debugPrint('seen_intro = $seenIntro');
    debugPrint('====================');
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, '/welcome');
  }

  void _onSkip() {
    _onFinish();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _introData.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: OverflowBox(
              maxWidth: double.infinity,
              maxHeight: double.infinity,
              child: Image.asset(
                'assets/images/Firefly.png',
                fit: BoxFit.cover,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
              ),
            ),
          ),
          // Flat white scrim (no gradient) so the background never fights with the text
          Positioned.fill(
            child: Container(color: Colors.white.withOpacity(0.88)),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, right: 16),
                    child: TextButton(
                      onPressed: _onSkip,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.PrimaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: _introData.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              height: 220,
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              child: Center(
                                child: Image.asset(
                                  height: 500,
                                  _introData[index]['image']!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.PrimaryColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'STEP ${index + 1} OF ${_introData.length}',
                                      style: TextStyle(
                                        fontFamily: 'Satoshi',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                        color: AppTheme.PrimaryColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    _introData[index]['title']!,
                                    style: const TextStyle(
                                      fontFamily: 'Satoshi',
                                      fontSize: 21,
                                      fontWeight: FontWeight.w800,
                                      color: _navy,
                                      height: 1.25,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _introData[index]['description']!,
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      fontFamily: 'Satoshi',
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade700,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: List.generate(
                          _introData.length,
                              (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 8),
                            height: 8,
                            width: _currentPage == index ? 24 : 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index ? AppTheme.PrimaryColor : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (isLastPage) {
                            _onFinish();
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeIn,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.PrimaryColor,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isLastPage ? 'Get Started' : 'Next',
                              style: const TextStyle(
                                fontFamily: 'Satoshi',
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                          ],
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

