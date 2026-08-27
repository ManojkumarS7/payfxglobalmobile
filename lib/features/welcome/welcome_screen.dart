import 'package:flutter/material.dart';
import 'package:payfxglobal/utils/app_theme.dart';
import 'package:payfxglobal/widgets/custom_button.dart';
import 'package:payfxglobal/widgets/no_internet_banner.dart';
import '../../services/app_services.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

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
          body: Stack(
            children: [
              /// Background Image
              Positioned.fill(
                child: Image.asset(
                  'assets/images/Firefly.png',
                  fit: BoxFit.contain,
                ),
              ),

              /// Main Content
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    bool isSmallScreen = constraints.maxHeight < 700;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        children: [
                          SizedBox(height: isSmallScreen ? 30 : 50),

                          /// HEADING
                          Text(
                            'Bank On-The-Go\nWith Our App',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 30 : 36,
                              height: 1.2,
                              color: AppTheme.TextColor,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Satoshi',
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 40 : 60),

                          Image.asset('assets/images/payfx.png', height: 120),

                          SizedBox(height: isSmallScreen ? 30 : 50),

                          Text(
                            'Welcome to the future of global finance with PayFX Global.\n\n'
                            'From international remittances to student financial solutions, '
                            'PayFX Global is designed to make your global banking experience '
                            'simple, secure, and seamless — anytime, anywhere.\n'
                            'Your world. Your money. One trusted platform. 💛',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: AppTheme.TextColor,
                              fontFamily: 'Satoshi',
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 20),

                          /// NEW USER BUTTON
                          AppPrimaryButton(
                            title: "Get Started",
                            onPressed: () {
                              Navigator.of(context).pushNamed('/email-entry');
                            },
                          ),

                          const SizedBox(height: 34),

                          /// LOGIN
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Already have an account? ',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                  fontFamily: 'Satoshi',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pushNamed('/login');
                                },
                                child: Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppTheme.PrimaryColor,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: isSmallScreen ? 25 : 35),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
