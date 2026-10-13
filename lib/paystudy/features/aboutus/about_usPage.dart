import 'package:flutter/material.dart';
import 'package:payfxglobal/utils/app_theme.dart';

class AboutUspage extends StatefulWidget {
  const AboutUspage({super.key});

  @override
  State<AboutUspage> createState() => _AboutUspageState();
}

class _AboutUspageState extends State<AboutUspage> {
  // ---- Palette (Matched with Dashboard) ----
  static const Color _navy = AppTheme.PrimaryColor;
  static const Color _ink = Color(0xFF0B1B3A);
  static const Color _accent = Color(0xFF0B1B3A);
  static const Color _bg = Color(0xFFF5F7FB);
  static const String _font = 'Satoshi';

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
          'About PayFX',
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
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: _navy.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 8))]),
                  child: Image.asset('assets/images/payfx.png', height: 80, fit: BoxFit.contain),
                ),
              ),
            ),
            const SizedBox(height: 32),
            _FadeSlide(index: i++, child: _buildContentCard('Our Story', 'PayFX Global is revolutionizing cross-border payments for the Indian diaspora. Built on strong banking partnerships, we offer a seamless, secure, and instant money transfer experience.')),
            const SizedBox(height: 20),
            _FadeSlide(index: i++, child: _buildContentCard('Our Mission', 'We strive to make "any-where-any-currency" money transfer simple and safe by providing a cutting-edge technology platform for students and individuals worldwide.')),
            const SizedBox(height: 20),
            _FadeSlide(index: i++, child: _buildContentCard('Our Vision', 'To become the most trusted global bridge for all international financial requirements, maintaining absolute compliance with regulatory frameworks.')),
            const SizedBox(height: 32),
            _FadeSlide(index: i++, child: const Text('Popular Countries', style: TextStyle(fontFamily: _font, fontSize: 18, fontWeight: FontWeight.w800, color: _ink))),
            const SizedBox(height: 16),
            _FadeSlide(index: i++, child: _buildCountryGrid()),
            const SizedBox(height: 32),
            _FadeSlide(index: i++, child: _buildAddressCard()),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildContentCard(String title, String body) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: _navy.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 6))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontFamily: _font, fontSize: 18, fontWeight: FontWeight.w800, color: _navy)),
            const SizedBox(height: 10),
            Text(body, style: TextStyle(fontFamily: _font, fontSize: 14, color: Colors.grey.shade700, height: 1.6, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _buildCountryGrid() {
    final countries = [
      ('USA', 'assets/flags/us.png'),
      ('Canada', 'assets/flags/ca.png'),
      ('UK', 'assets/flags/uk.png'),
      ('Germany', 'assets/flags/germany.png'),
      ('Australia', 'assets/flags/australia.png'),
      ('France', 'assets/flags/france.png'),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.9),
      itemCount: countries.length,
      itemBuilder: (context, idx) => Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: _navy.withOpacity(0.04), blurRadius: 10)]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipOval(child: Image.asset(countries[idx].$2, width: 36, height: 36, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.flag_rounded, color: _navy))),
            const SizedBox(height: 10),
            Text(countries[idx].$1, style: const TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.w800, color: _ink)),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: _navy.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 8))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Get in Touch', style: TextStyle(fontFamily: _font, fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 8),
            Container(width: 40, height: 3, decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            _contactItem(Icons.location_on_rounded, 'PayFX Fintech Solutions Private Limited\n303, Raheja Center, Avinashi Rd, Coimbatore - 641018'),
            _contactItem(Icons.email_rounded, 'care@payfxglobal.com'),
            _contactItem(Icons.phone_rounded, '+91 99524 77555'),
            _contactItem(Icons.business_rounded, 'Branches: Bangalore, Chennai, Delhi, Mumbai, Pune, Kochi, Hyderabad.'),
          ],
        ),
      );

  Widget _contactItem(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: _accent, size: 20),
            const SizedBox(width: 14),
            Expanded(child: Text(text, style: const TextStyle(fontFamily: _font, fontSize: 13, color: Colors.white, height: 1.4, fontWeight: FontWeight.w600))),
          ],
        ),
      );
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
