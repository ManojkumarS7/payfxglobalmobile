import 'package:flutter/material.dart';

class PayUniLoadingWidget extends StatefulWidget {
  final double size;
  final String? message;

  const PayUniLoadingWidget({super.key, this.size = 60.0, this.message});

  @override
  State<PayUniLoadingWidget> createState() => _PayUniLoadingWidgetState();
}

class _PayUniLoadingWidgetState extends State<PayUniLoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _animation.value * 2 * 3.14159,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE53E3E).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: SizedBox(
                        width: widget.size * 0.6,
                        height: widget.size * 0.4,
                        child: CustomPaint(painter: PayUniIconPainter()),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (widget.message != null) ...[
            const SizedBox(height: 16),
            Text(
              widget.message!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class PayUniLogo extends StatelessWidget {
  final double width;
  final double height;

  const PayUniLogo({super.key, this.width = 200.0, this.height = 60.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Red geometric icon
          SizedBox(
            width: height * 0.83, // Maintain aspect ratio
            height: height * 0.75,
            child: CustomPaint(painter: PayUniIconPainter()),
          ),

          SizedBox(width: width * 0.08),

          // PAYUNI text
          Text(
            'PayFX Global',
            style: TextStyle(
              fontSize: height * 0.4,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748), // Dark gray from official logo
              letterSpacing: width * 0.002,
            ),
          ),
        ],
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
