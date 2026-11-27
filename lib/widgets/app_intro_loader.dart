import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:payfxglobal/utils/app_theme.dart';

class AppIntroLoader extends StatefulWidget {
  const AppIntroLoader({super.key});

  @override
  State<AppIntroLoader> createState() => _AppIntroLoaderState();
}

class _AppIntroLoaderState extends State<AppIntroLoader>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    // Rotation for orbiting icons
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Smooth floating effect for the central globe
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Glow Effect
          Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.PrimaryColor.withOpacity(0.1),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          // Central Animation: Earth, Rupee, and Dollar
          Center(
            child: SizedBox(
              height: 400,
              width: 400,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Earth (Globe) - Center
                  AnimatedBuilder(
                    animation: _floatController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, 15 * math.sin(_floatController.value * math.pi)),
                        child: Icon(
                          Icons.public,
                          size: 100,
                          color: Colors.blue.shade600,
                        ),
                      );
                    },
                  ),

                  // Orbiting Rupee Icon
                  _buildOrbitingIcon(
                    icon: Icons.currency_rupee,
                    color: AppTheme.PrimaryColor,
                    radius: 120,
                    speed: 1.0,
                    angleOffset: 0,
                  ),

                  // Orbiting Dollar Icon
                  _buildOrbitingIcon(
                    icon: Icons.attach_money,
                    color: Colors.green.shade600,
                    radius: 150,
                    speed: 0.8,
                    angleOffset: math.pi,
                  ),
                ],
              ),
            ),
          ),

          // PayFX Logo at the bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 80.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 30 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Image.asset(
                      'assets/images/payfx.png',
                      width: 180,
                      errorBuilder: (context, error, stackTrace) => Text(
                        'PayFX',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.PrimaryColor,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  const SizedBox(
                    width: 35,
                    height: 35,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.PrimaryColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrbitingIcon({
    required IconData icon,
    required Color color,
    required double radius,
    required double speed,
    required double angleOffset,
  }) {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        final angle = (_rotationController.value * 2 * math.pi * speed) + angleOffset;
        final x = radius * math.cos(angle);
        final y = radius * math.sin(angle) * 0.45; // Elliptical path

        return Transform.translate(
          offset: Offset(x, y),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: color,
              size: 26,
            ),
          ),
        );
      },
    );
  }
}
