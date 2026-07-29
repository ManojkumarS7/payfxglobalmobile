import 'package:flutter/material.dart';
import 'package:payfxglobal/widgets/launcher_icon_widget.dart';

void main() {
  runApp(const IconGeneratorApp());
}

class IconGeneratorApp extends StatelessWidget {
  const IconGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PayUni Icon Generator',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const IconGeneratorScreen(),
    );
  }
}

class IconGeneratorScreen extends StatelessWidget {
  const IconGeneratorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('PayUni Launcher Icon Generator'),
        backgroundColor: const Color(0xFFE53E3E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'PayUni Launcher Icons',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 30),

            // Main 1024x1024 icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    '1024x1024 (Master)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  const PayUniLauncherIcon(size: 200),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Different sizes
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                _buildIconPreview('192x192\n(xxxhdpi)', 96),
                _buildIconPreview('144x144\n(xxhdpi)', 72),
                _buildIconPreview('96x96\n(xhdpi)', 48),
                _buildIconPreview('72x72\n(hdpi)', 36),
                _buildIconPreview('48x48\n(mdpi)', 24),
              ],
            ),

            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE53E3E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE53E3E).withOpacity(0.3),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Instructions:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '1. Take a screenshot of each icon size\n'
                    '2. Crop to exact square dimensions\n'
                    '3. Save as PNG with appropriate names\n'
                    '4. Use flutter_launcher_icons to apply\n'
                    '5. Run: flutter pub run flutter_launcher_icons:main',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF2D3748),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconPreview(String label, double size) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 8),
          PayUniLauncherIcon(size: size),
        ],
      ),
    );
  }
}
