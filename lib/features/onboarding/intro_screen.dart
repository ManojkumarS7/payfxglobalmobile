import 'package:flutter/material.dart';
import 'package:payfxglobal/utils/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      'description': 'PayFX Global provides secure and reliable international remittance services for students, individuals, and businesses. We support fast cross-border money transfers with competitive exchange rates, transparent processing, and dedicated customer assistance for global payment needs',
      'image': 'assets/images/payfx_logo2.png',
    },
    {
      'title': 'Education Loan',
      'description': 'PayFX Global provides education loan assistance services by supporting students in identifying suitable financing options for overseas education. We assist with documentation guidance, application support, and coordination with financial institutions to simplify the loan process',
      'image': 'assets/images/payfx_logo2.png',
    },
    {
      'title': 'Blocked Account / GIC Account Opening Assitance',
      'description':
      'PayFX Global provides assistance for opening Blocked Accounts and Guaranteed Investment Certificate (GIC) accounts required for international education and visa purposes. We support students with account opening procedures, documentation requirements, and onboarding guidance for a smooth process.',
      'image': 'assets/images/payfx_logo2.png',
    },
  ];

  void _onFinish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_intro', true);
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body:

      Stack(
        children: [
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
          SafeArea(


            child: Column(
              children: [
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
                        padding: const EdgeInsets.all(30.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Replace with Icon or Placeholder if image is missing
                            Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Image.asset(
                                  _introData[index]['image']!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),

                            const SizedBox(height: 40),
                            Text(
                              _introData[index]['title']!,
                              style: const TextStyle(
                                fontFamily: 'Satoshi',
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.TextColor,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _introData[index]['description']!,
                              textAlign: TextAlign.left,
                              style: const TextStyle(
                                fontFamily: 'Satoshi',
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
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
                              color: _currentPage == index
                                  ? AppTheme.PrimaryColor
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (_currentPage == _introData.length - 1) {
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _currentPage == _introData.length - 1 ? 'Get Started' : 'Next',
                          style: const TextStyle(
                            fontFamily: 'Satoshi',
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
