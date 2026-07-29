import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:payfxglobal/utils/app_theme.dart';

class CustomLoadingIndicator extends StatefulWidget {
  final double size;
  const CustomLoadingIndicator({super.key, this.size = 100});

  @override
  State<CustomLoadingIndicator> createState() => _CustomLoadingIndicatorState();
}

class _CustomLoadingIndicatorState extends State<CustomLoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _rotateController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rotating gradient arc instead of a plain spinning ring
          AnimatedBuilder(
            animation: _rotateController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotateController.value * 2 * math.pi,
                child: child,
              );
            },
            child: SizedBox(
              width: widget.size + 24,
              height: widget.size + 24,
              child: CustomPaint(
                painter: _ArcPainter(color: const Color(0xFFF9C63D)),
              ),
            ),
          ),

          // Logo with a soft pulse
          ScaleTransition(
            scale: Tween(begin: 0.92, end: 1.0).animate(_pulseAnimation),
            child: FadeTransition(
              opacity: Tween(begin: 0.6, end: 1.0).animate(_pulseAnimation),
              child: Image.asset(
                'assets/images/payfx.png',
                width: widget.size,
                height: widget.size,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.account_balance_wallet,
                  color: Color(0xFFF9C63D),
                  size: 40,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final Color color;
  const _ArcPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.width / 2 - 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 2,
        colors: [
          color.withOpacity(0.0),
          color.withOpacity(0.9),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      math.pi * 1.5,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) => false;
}

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: const CustomLoadingIndicator(),
    );
  }
}

class ButtonLoader extends StatelessWidget {
  const ButtonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return LoadingAnimationWidget.staggeredDotsWave(
      color: AppTheme.PrimaryColor,
      size: 30,
    );
  }
}
