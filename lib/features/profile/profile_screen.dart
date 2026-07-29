import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:payfxglobal/models/user/user.dart';
import 'package:payfxglobal/utils/app_theme.dart';
import 'package:payfxglobal/widgets/custom_app_bar.dart';
import 'package:payfxglobal/widgets/logout_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  final User user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isBiometricEnabled = false;

  static const Color _navy = AppTheme.TextColor;
  static const Color _amber = AppTheme.PrimaryColor;

  @override
  void initState() {
    super.initState();
    debugPrint('Profile User Data: ${widget.user.toJson()}');
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppPrimaryAppBar(
        title: 'Profile',
        showBackButton: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _buildProfileHeader(),
              const SizedBox(height: 20),
              // _buildCountryAndMemberSinceRow(),
              const SizedBox(height: 16),
              const Divider(height: 1, thickness: 1, color: Color(0xFFF1E9D8)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildBiometricTile(),
                    const SizedBox(height: 20),
                    _buildActionButtons(context),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Header: avatar + verified badge, name, customer ID with copy button
  // ---------------------------------------------------------------------

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: Colors.white,
                child: Image.asset('assets/images/payfx_logo2.png'),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.verified, size: 14, color: Colors.green),
                      SizedBox(width: 6),
                      Text(
                        'Verified Account',
                        style: TextStyle(fontFamily: 'Satoshi', fontSize: 11, fontWeight: FontWeight.w700, color: Colors.green),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.user.fullName.toUpperCase(),
                  style: const TextStyle(fontFamily: 'Satoshi', fontSize: 19, fontWeight: FontWeight.w800, color: _navy, height: 1.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------

  Widget _statTile({required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: _amber.withOpacity(0.12), shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: _amber),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontFamily: 'Satoshi', fontSize: 11.5, color: Colors.grey.shade600)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontFamily: 'Satoshi', fontSize: 14, fontWeight: FontWeight.w700, color: _navy),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Biometric Lock toggle
  // ---------------------------------------------------------------------
  Widget _buildBiometricTile() {
    return _settingsTile(
      icon: Icons.fingerprint,
      iconColor: _navy,
      title: 'Biometric Lock',
      subtitle: 'Secure login with your biometrics',
      trailing: Switch(
        value: _isBiometricEnabled,
        onChanged: (value) async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('biometric_lock_enabled', value);
          setState(() {
            _isBiometricEnabled = value;
          });
        },
        activeColor: _amber,
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Action list
  // ---------------------------------------------------------------------
  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        _settingsTile(
          icon: Icons.support_agent_outlined,
          iconColor: _navy,
          title: 'Support Center',
          subtitle: 'Get help and contact support',
          trailing: const Icon(Icons.chevron_right, color: _amber),
          onTap: () => Navigator.pushNamed(context, '/support'),
        ),
        const SizedBox(height: 12),
        _settingsTile(
          icon: Icons.shield_outlined,
          iconColor: _navy,
          title: 'Payment Terms & Condition',
          subtitle: 'Applicable for Online and Offline Payment Instructions',
          trailing: const Icon(Icons.chevron_right, color: _amber),
          onTap: () => Navigator.pushNamed(context, '/payment-terms'),
        ),
        const SizedBox(height: 12),
        _settingsTile(
          icon: Icons.info_outline,
          iconColor: _navy,
          title: 'About Us',
          subtitle: 'Read our company profile',
          trailing: const Icon(Icons.chevron_right, color: _amber),
          onTap: () => Navigator.pushNamed(context, '/about-us'),
        ),
        const SizedBox(height: 12),
        _settingsTile(
          icon: Icons.logout,
          iconColor: _navy,
          title: 'Logout',
          subtitle: 'Sign out from your account',
          trailing: const Icon(Icons.chevron_right, color: _amber),
          onTap: () => LogoutDialog.show(context),
        ),
        const SizedBox(height: 16),
        const Divider(height: 1, thickness: 1, color: Color(0xFFF1E9D8)),
        const SizedBox(height: 16),
        _settingsTile(
          icon: Icons.highlight_remove_outlined,
          iconColor: Colors.red,
          title: 'Close  Account',
          subtitle: 'Close your personal account',
          titleColor: Colors.red,
          trailing: const Icon(Icons.chevron_right, color: Colors.red),
          onTap: () => Navigator.pushNamed(context, '/delete-account'),
        ),
      ],
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: titleColor ?? _navy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontFamily: 'Satoshi', fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
