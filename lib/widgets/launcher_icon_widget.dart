import 'package:flutter/material.dart';

/// Widget for generating PayUni launcher icons
/// This should be used with flutter_launcher_icons package
class PayUniLauncherIcon extends StatelessWidget {
  final double size;
  final bool showBackground;

  const PayUniLauncherIcon({
    super.key,
    this.size = 1024.0,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: showBackground
          ? BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                size * 0.22,
              ), // iOS rounded corners
            )
          : null,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // PayUni geometric icon - larger for better visibility
            SizedBox(
              width: size * 0.45,
              height: size * 0.27,
              child: CustomPaint(painter: PayUniLauncherIconPainter()),
            ),

            SizedBox(height: size * 0.03),

            // PAYUNI text
            Text(
              'PAYUNI',
              style: TextStyle(
                fontSize: size * 0.09,
                fontWeight: FontWeight.w900, // Extra bold for launcher
                color: const Color(0xFF2D3748),
                letterSpacing: size * 0.001,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for the official PayUni geometric icon
class PayUniLauncherIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint redPaint = Paint()
      ..color =
          const Color(0xFFE53E3E) // Official PayUni red
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final Paint whitePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final double w = size.width;
    final double h = size.height;

    // Adjusted paths based on the official SVG
    // Top left parallelogram: M0 15 L20 0 L35 0 L15 15 Z
    Path topLeft = Path();
    topLeft.moveTo(0, h * 0.33);
    topLeft.lineTo(w * 0.4, 0);
    topLeft.lineTo(w * 0.7, 0);
    topLeft.lineTo(w * 0.3, h * 0.33);
    topLeft.close();
    canvas.drawPath(topLeft, redPaint);

    // Top right triangle: M35 0 L50 15 L35 30 Z
    Path topRight = Path();
    topRight.moveTo(w * 0.7, 0);
    topRight.lineTo(w, h * 0.33);
    topRight.lineTo(w * 0.7, h * 0.67);
    topRight.close();
    canvas.drawPath(topRight, redPaint);

    // Bottom left parallelogram: M0 15 L15 15 L35 30 L15 45 Z
    Path bottomLeft = Path();
    bottomLeft.moveTo(0, h * 0.33);
    bottomLeft.lineTo(w * 0.3, h * 0.33);
    bottomLeft.lineTo(w * 0.7, h * 0.67);
    bottomLeft.lineTo(w * 0.3, h);
    bottomLeft.close();
    canvas.drawPath(bottomLeft, redPaint);

    // Center triangle (lighter): M15 15 L35 0 L35 30 Z
    Path center = Path();
    center.moveTo(w * 0.3, h * 0.33);
    center.lineTo(w * 0.7, 0);
    center.lineTo(w * 0.7, h * 0.67);
    center.close();
    canvas.drawPath(center, whitePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
