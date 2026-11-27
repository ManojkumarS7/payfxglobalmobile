import 'package:flutter/material.dart';
import 'package:payfxglobal/models/user/user.dart';
import 'package:payfxglobal/widgets/logout_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:payfxglobal/utils/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  final User user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isBiometricEnabled = false;

  // ---- Palette (Matched with Dashboard) ----
  static const Color _navy =  AppTheme.PrimaryColor;
  static const Color _ink = Color(0xFF0B1B3A);
  static const Color _accent = Color(0xFFFFC72C);
  static const Color _bg = Color(0xFFF5F7FB);
  static const String _font = 'Satoshi';

  @override
  void initState() {
    super.initState();
    _loadBiometricStatus();
  }

  Future<void> _loadBiometricStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isBiometricEnabled = prefs.getBool('biometric_lock_enabled') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {

    int i = 0; // for stagger animation
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontFamily: _font,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: _ink,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FadeSlide(index: i++, child: _buildProfileHeader()),
              const SizedBox(height: 28),
              _FadeSlide(index: i++, child: _sectionTitle('Security')),
              const SizedBox(height: 12),
              _FadeSlide(index: i++, child: _buildBiometricTile()),
              const SizedBox(height: 28),
              _FadeSlide(index: i++, child: _sectionTitle('Account')),
              const SizedBox(height: 12),
              _FadeSlide(index: i++, child: _buildAccountActions(context)),
              const SizedBox(height: 28),
              _FadeSlide(index: i++, child: _sectionTitle('Danger Zone')),
              const SizedBox(height: 12),
              _FadeSlide(index: i++, child: _buildDangerZone(context)),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
            fontFamily: _font,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: _ink,
            letterSpacing: 0.2),
      );

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: _navy.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 8))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration:
                const BoxDecoration(shape: BoxShape.circle, color: _accent),
            child: CircleAvatar(
              radius: 36,
              backgroundColor: _navy,
              child: Text(
                _getInitials(widget.user.fullName),
                style: const TextStyle(
                    fontFamily: _font,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user.fullName,
                  style: const TextStyle(
                      fontFamily: _font,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                      letterSpacing: -0.5),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5F8E0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded,
                          size: 14, color: Color(0xFF0F7B4F)),
                      SizedBox(width: 5),
                      Text('Verified Account',
                          style: TextStyle(
                              fontFamily: _font,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F7B4F))),
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

  String _getInitials(String name) {
    if (name.isEmpty) return '??';
    List<String> parts = name.trim().split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Widget _buildBiometricTile() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: _navy.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: const Color(0xFFE6F0FF),
                borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.fingerprint_rounded, color: _navy, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Biometric Lock',
                    style: TextStyle(
                        fontFamily: _font,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _ink)),
                Text('Secure login with biometrics',
                    style: TextStyle(
                        fontFamily: _font, fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isBiometricEnabled,
            activeColor: _accent,
            activeTrackColor: _navy.withOpacity(0.1),
            onChanged: (value) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('biometric_lock_enabled', value);
              setState(() {
                _isBiometricEnabled = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActions(BuildContext context) {
    return Column(
      children: [
        _profileActionTile(
          icon: Icons.support_agent_rounded,
          title: 'Support Center',
          subtitle: 'Get help and contact support',
          tint: const Color(0xFFFFF1DB),
          onTap: () => Navigator.pushNamed(context, '/support'),
        ),
        const SizedBox(height: 12),
        _profileActionTile(
          icon: Icons.gavel_rounded,
          title: 'Terms & Conditions',
          subtitle: 'Legal and privacy policy',
          tint: const Color(0xFFE5F8E0),
          onTap: () => Navigator.pushNamed(context, '/payment-terms'),
        ),
        const SizedBox(height: 12),
        _profileActionTile(
          icon: Icons.info_outline_rounded,
          title: 'About PayFX',
          subtitle: 'Version 1.42.76',
          tint: const Color(0xFFE6F0FF),
          onTap: () => Navigator.pushNamed(context, '/about-us'),
        ),
        const SizedBox(height: 12),
        _profileActionTile(
          icon: Icons.logout_rounded,
          title: 'Logout',
          subtitle: 'Sign out from your account',
          tint: const Color(0xFFFEE2E2),
          iconColor: Colors.redAccent,
          onTap: () => LogoutDialog.show(context),
        ),
      ],
    );
  }

  Widget _buildDangerZone(BuildContext context) {
    return _profileActionTile(
      icon: Icons.no_accounts_rounded,
      title: 'Close Account',
      subtitle: 'Permanently delete your account',
      tint: Colors.red.withOpacity(0.08),
      iconColor: Colors.red,
      textColor: Colors.red,
      onTap: () => Navigator.pushNamed(context, '/delete-account'),
    );
  }

  Widget _profileActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color tint,
    Color? iconColor,
    Color? textColor,
    VoidCallback? onTap,
  }) {
    return _Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
                color: _navy.withOpacity(0.05),
                blurRadius: 14,
                offset: const Offset(0, 6))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: tint, borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: iconColor ?? _navy, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontFamily: _font,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: textColor ?? _ink)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontFamily: _font, fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Colors.grey),
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
        child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)), child: child),
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
