import 'package:flutter/material.dart';

class AppIconWidget extends StatelessWidget {
  final double size;

  const AppIconWidget({super.key, this.size = 1024.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE53E3E).withOpacity(0.3),
            blurRadius: size * 0.02,
            offset: Offset(0, size * 0.01),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // PayUni geometric icon
            SizedBox(
              width: size * 0.4,
              height: size * 0.24,
              child: CustomPaint(painter: PayUniIconPainter()),
            ),

            SizedBox(height: size * 0.05),

            // PAYUNI text
            Text(
              'PAYUNI',
              style: TextStyle(
                fontSize: size * 0.08,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3748),
                letterSpacing: size * 0.002,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PayUniIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint redPaint = Paint()
      ..color =
          const Color(0xFFE53E3E) // Official PayUni red
      ..style = PaintingStyle.fill;

    final Paint whitePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final double w = size.width;
    final double h = size.height;

    // Top left parallelogram
    Path topLeft = Path();
    topLeft.moveTo(0, h * 0.33);
    topLeft.lineTo(w * 0.4, 0);
    topLeft.lineTo(w * 0.7, 0);
    topLeft.lineTo(w * 0.3, h * 0.33);
    topLeft.close();
    canvas.drawPath(topLeft, redPaint);

    // Top right triangle
    Path topRight = Path();
    topRight.moveTo(w * 0.7, 0);
    topRight.lineTo(w, h * 0.33);
    topRight.lineTo(w * 0.7, h * 0.67);
    topRight.close();
    canvas.drawPath(topRight, redPaint);

    // Bottom left parallelogram
    Path bottomLeft = Path();
    bottomLeft.moveTo(0, h * 0.33);
    bottomLeft.lineTo(w * 0.3, h * 0.33);
    bottomLeft.lineTo(w * 0.7, h * 0.67);
    bottomLeft.lineTo(w * 0.3, h);
    bottomLeft.close();
    canvas.drawPath(bottomLeft, redPaint);

    // Center highlight triangle
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
