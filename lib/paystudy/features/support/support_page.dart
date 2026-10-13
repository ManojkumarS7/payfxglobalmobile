import 'package:flutter/material.dart';
import 'package:payfxglobal/utils/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  // ---- Palette (Matched with Dashboard) ----
  static const Color _navy = AppTheme.PrimaryColor;
  static const Color _ink = Color(0xFF0B1B3A);
  static const Color _accent = Color(0xFFFFC72C);
  static const Color _bg = Color(0xFFF5F7FB);
  static const String _font = 'Satoshi';

  Future<void> _openEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'care@payfxglobal.com',
      queryParameters: {'subject': 'Support Request'},
    );
    if (!await launchUrl(emailUri, mode: LaunchMode.externalApplication)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No email app found')));
    }
  }

  Future<void> _makeCall() async {
    final Uri telUri = Uri(scheme: 'tel', path: '+919952477555');
    if (!await launchUrl(telUri, mode: LaunchMode.externalApplication)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not initiate call')));
    }
  }

  @override
  Widget build(BuildContext context) {
    int i = 0;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _ink, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Support Center',
          style: TextStyle(fontFamily: _font, fontSize: 22, fontWeight: FontWeight.w800, color: _ink, letterSpacing: -0.5),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FadeSlide(
              index: i++,
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [BoxShadow(color: _navy.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 8))],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(color: Color(0xFFE6F0FF), shape: BoxShape.circle),
                      child: const Icon(Icons.headset_mic_rounded, color: _navy, size: 36),
                    ),
                    const SizedBox(height: 24),
                    const Text('How can we help you?', style: TextStyle(fontFamily: _font, fontSize: 22, fontWeight: FontWeight.w900, color: _ink)),
                    const SizedBox(height: 10),
                    Text('Our dedicated support team is available to assist you with any questions about your global transfers.', 
                        textAlign: TextAlign.center, style: TextStyle(fontFamily: _font, fontSize: 14, color: Colors.grey.shade600, height: 1.5, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            _FadeSlide(index: i++, child: const Text('Contact Channels', style: TextStyle(fontFamily: _font, fontSize: 18, fontWeight: FontWeight.w800, color: _ink))),
            const SizedBox(height: 16),
            _FadeSlide(index: i++, child: _supportActionTile(
              icon: Icons.call_rounded,
              title: 'Call Support',
              subtitle: '+91 99524 77555',
              tint: const Color(0xFFE5F8E0),
              iconColor: const Color(0xFF0F7B4F),
              onTap: _makeCall,
            )),
            const SizedBox(height: 14),
            _FadeSlide(index: i++, child: _supportActionTile(
              icon: Icons.mail_rounded,
              title: 'Email Us',
              subtitle: 'care@payfxglobal.com',
              tint: const Color(0xFFFFF1DB),
              iconColor: const Color(0xFFE59A00),
              onTap: _openEmail,
            )),
            const SizedBox(height: 32),
            _FadeSlide(
              index: i++,
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: _navy.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6))]),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_rounded, color: Colors.white, size: 24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Business Hours', style: TextStyle(fontFamily: _font, fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                          const SizedBox(height: 2),
                          Text('Mon - Fri: 9:30 AM to 6:30 PM (IST)', style: TextStyle(fontFamily: _font, fontSize: 12, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _supportActionTile({required IconData icon, required String title, required String subtitle, required Color tint, required Color iconColor, required VoidCallback onTap}) {
    return _Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: _navy.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontFamily: _font, fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
          ],
        ),
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
      duration: Duration(milliseconds: 400 + index * 80),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child),
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
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
