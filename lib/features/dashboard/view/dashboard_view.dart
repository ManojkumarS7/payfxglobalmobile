import 'package:flutter/material.dart';
import 'package:payfxglobal/features/auth/view/login_screen.dart';
import 'package:payfxglobal/services/api_service.dart';
import 'package:payfxglobal/services/app_services.dart';
import 'package:payfxglobal/utils/app_theme.dart';
import 'package:payfxglobal/widgets/no_internet_banner.dart';
import 'package:payfxglobal/widgets/custom_loading_indicator.dart';
import 'package:payfxglobal/utils/session_manager.dart';

import '../service/dashboard_api_service.dart';
import '../viewmodel/dashbaord_view_model.dart';
import 'package:payfxglobal/features/transaction_history/view/transaction_history_screen.dart';
import 'package:payfxglobal/features/profile/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const DashboardScreen({super.key, required this.userData});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DashboardViewModel vm;

  static const Color _navy = Color(0xFF16305C);


  int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();
    ApiService.initializeApiKey();
    SessionManager.updateLastActive();
    vm = DashboardViewModel(service: DashboardService());
    vm.initialize(widget.userData);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      LoginScreen.askBiometricPermission(context);
    });
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppTheme.PrimaryColor;

    return StreamBuilder<bool>(
      stream: networkService.internetStatus,
      initialData: true,
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? true;

        if (!isConnected) {
          return NoInternetScreen(onRetry: () => vm.refresh(widget.userData));
        }

        return AnimatedBuilder(
          animation: vm,
          builder: (context, _) {
            if (vm.isLoading) return const LoadingOverlay();

            return Scaffold(
              backgroundColor: AppTheme.backgroundColor,
              body: SafeArea(
                child: _buildBody(primaryColor),
              ),
              bottomNavigationBar: _buildBottomNavBar(),
            );
          },
        );
      },
    );
  }

  Widget _buildBody(Color primaryColor) {
    switch (_selectedNavIndex) {
      case 0:
        return _buildHomeTab(primaryColor);
      case 1:
        return TransactionHistoryScreen(userId: vm.currentUser.userId);
      case 2:
        return ProfileScreen(user: vm.currentUser);
      default:
        return _buildHomeTab(primaryColor);
    }
  }

  Widget _buildHomeTab(Color primaryColor) {
    final isKycActionNeeded = !vm.hasSenderDetails || !vm.hasKycDocuments;
    return RefreshIndicator(
      onRefresh: () => vm.refresh(widget.userData),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBar(primaryColor),
            const SizedBox(height: 20),
            _buildGreetingHeader(primaryColor),
            const SizedBox(height: 20),
            _buildQuickTransferBanner(),
            const SizedBox(height: 20),
            _buildQuickActionsRow(),
            const SizedBox(height: 28),
            _buildServicesHeader(),
            const SizedBox(height: 12),
            _buildServicesList(),
            const SizedBox(height: 16),
            _buildEducationLoanPromo(),
            const SizedBox(height: 16),
            _buildGicAndBlockedAccountRow(),
            if (isKycActionNeeded)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _buildActionRequiredSection(primaryColor),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(Color primaryColor) {
    return Row(
      children: [
        Image.asset(
          'assets/images/payfx.png',
          width: 120, height: 100, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Text('PayFX', style: TextStyle(fontFamily: 'Satoshi', fontSize: 22, fontWeight: FontWeight.w800, color: _navy)),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.pushNamed(context, '/notifications'),
          icon: const Icon(Icons.notifications_none_rounded, color: _navy, size: 26),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () => setState(() => _selectedNavIndex = 2),
          child: CircleAvatar(
            radius: 20, backgroundColor: _navy,
            child: Text(
              vm.initialsFromName(vm.currentUser.fullName),
              style: const TextStyle(fontFamily: 'Satoshi', color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGreetingHeader(Color primaryColor) {
    return Stack(
      children: [

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_greeting()} 👋', style: TextStyle(fontFamily: 'Satoshi', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
            const SizedBox(height: 6),
            Text(vm.currentUser.fullName, style: const TextStyle(fontFamily: 'Satoshi', fontSize: 26, fontWeight: FontWeight.w800, color: _navy)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, size: 16, color: Colors.green),
                  const SizedBox(width: 6),
                  Text('Verified Customer', style: TextStyle(fontFamily: 'Satoshi', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickTransferBanner() {
    return GestureDetector(
      onTap: _handleMoneyTransferPressed,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(

          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color:AppTheme.PrimaryColor)
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20, backgroundColor: _navy,
              child: Text(vm.initialsFromName(vm.currentUser.fullName), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 14),
            const Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quick Transfer', style: TextStyle(fontFamily: 'Satoshi', fontSize: 17, fontWeight: FontWeight.w800, color: _navy)),
                Text('Send money instantly to loved ones', style: TextStyle(fontFamily: 'Satoshi', fontSize: 13, color: _navy)),
              ],
            )),
            const CircleAvatar(radius: 15, backgroundColor: _navy, child: Icon(Icons.arrow_forward, color: Colors.white, size: 20)),
          ],
        ),
      ),
    );
  }



  Widget _buildQuickActionsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _quickActionIcon(label: 'Add Recipient', icon: Icons.person_add, background: AppTheme.PrimaryColor.withOpacity(0.1), iconColor: AppTheme.PrimaryColor, onTap: () => _handleAddRecipientPressed()),
        _quickActionIcon(label: 'History', icon: Icons.history_rounded, background:AppTheme.PrimaryColor.withOpacity(0.1), iconColor: AppTheme.PrimaryColor, onTap: () => setState(() => _selectedNavIndex = 1)),
        _quickActionIcon(label: 'Rates', icon: Icons.show_chart_rounded, background:AppTheme.PrimaryColor.withOpacity(0.1), iconColor: AppTheme.PrimaryColor, onTap: () => Navigator.pushNamed(context, '/currency-rates')),
        _quickActionIcon(label: 'Support', icon: Icons.headset_mic_rounded, background: AppTheme.PrimaryColor.withOpacity(0.1), iconColor: AppTheme.PrimaryColor, onTap: () => Navigator.pushNamed(context, '/support')),
      ],
    );
  }



  Widget _quickActionIcon({required String label, required IconData icon, required Color background, required Color iconColor, VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(children: [
          Container(width: 56, height: 56, decoration: BoxDecoration(color: background, shape: BoxShape.circle), child: Icon(icon, color: AppTheme.PrimaryColor, size: 26)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontFamily: 'Satoshi', fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.TextColor)),
        ]),
      ),
    );
  }

  Widget _buildServicesHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Services', style: TextStyle(fontFamily: 'Satoshi', fontSize: 18, fontWeight: FontWeight.w800, color: _navy)),

      ],
    );
  }

  Widget _buildServicesList() {
    return Column(
      children: [

        _serviceListTile(icon: Icons.school_rounded, title: 'Education Loan', subtitle: 'Supporting your academic dreams', onTap: () => Navigator.pushNamed(context, '/education-loan')),
        const SizedBox(height: 12),
        _serviceListTile(icon: Icons.lock_outline, title: 'GIC & Blocked Account', subtitle: 'Open your accounts instantly', onTap: () => Navigator.pushNamed(context, '/account-opening')),
        const SizedBox(height: 12),
        _serviceListTile(icon: Icons.send_rounded, title: 'Money Transfer', subtitle: 'Fast and secure global transfers', onTap: _handleMoneyTransferPressed),
      ],
    );
  }

  Widget _serviceListTile({Key? key, required IconData icon, required String title, required String subtitle, VoidCallback? onTap}) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
        child: Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: AppTheme.PrimaryColor.withOpacity(0.05), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: AppTheme.PrimaryColor, size: 24)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontFamily: 'Satoshi', fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.TextColor)), Text(subtitle, style: TextStyle(fontFamily: 'Satoshi', fontSize: 12, color: Colors.grey.shade600))])),
          Icon(Icons.chevron_right, color: AppTheme.PrimaryColor),
        ]),
      ),
    );
  }

  Widget _buildEducationLoanPromo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Education Loan', style: TextStyle(fontFamily: 'Satoshi', fontSize: 20, fontWeight: FontWeight.w800, color: _navy)),
          const SizedBox(height: 8),
          Text('Study Abroad - Your gateway to hassle-free international education loans — from application to disbursal, without the runaround.', style: TextStyle(fontFamily: 'Satoshi', fontSize: 13, color: Colors.grey.shade700)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/education-loan'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.PrimaryColor, foregroundColor: Colors.white, shape: const StadiumBorder()),
            child: const Text('Check Eligibility', style: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }


  Widget _buildGicAndBlockedAccountRow() {
    return Row(
      children: [
        Expanded(
          child: _infoCard(
            title: 'GIC',
            subtitle: 'Secure investment for Canada study visa',
            image: Image.asset('assets/flags/ca.png'),
            color: _navy,
            icon: Icons.shield_outlined,
            onTap: () => _showAccountDetailSheet('GIC'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _infoCard(
            title: 'Blocked Account',
            subtitle: 'Open your blocked account for Germany',
            image: Image.asset('assets/flags/germany.png'),
            color: _navy,
            icon: Icons.lock,
            onTap: () => _showAccountDetailSheet('Blocked Account'),
          ),
        ),
      ],
    );
  }

  void _showAccountDetailSheet(String type) {
    final bool isGic = type == 'GIC';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(
                  isGic ? Icons.shield_outlined : Icons.lock,
                  color: _navy,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  isGic ? 'GIC (Canada)' : 'Blocked Account (Germany)',
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _navy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              isGic
                  ? 'Guaranteed Investment Certificate (GIC) is a mandatory requirement for international students applying for a Canada Study Permit under the SDS (Student Direct Stream) program.'
                  : 'A Blocked Account is a special type of bank account for international students and job seekers in Germany to prove they have enough funds to cover their living expenses.',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'What we offer:',
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.TextColor,
              ),
            ),
            const SizedBox(height: 12),
            if (isGic) ...[
              _buildOfferItem('Simplified application with top Canadian banks (CIBC, ICICI Canada, Scotiabank, BMO, RBC).'),
              _buildOfferItem('Fast processing and direct transfer from India.'),
              _buildOfferItem('Complete guidance on documentation.'),
            ] else ...[
              _buildOfferItem('Partnership with authorized providers (Studley, Expatrio, Coracle, Fintiba).'),
              _buildOfferItem('Best exchange rates and low service fees.'),
              _buildOfferItem('Fast account opening confirmation for visa application.'),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/account-opening');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.PrimaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isGic ? 'Open your GIC Account' : 'Open Blocked Account',
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required String subtitle,
    required  Image image,
    required Color color,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.PrimaryColor)
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 14),

            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: image,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _navy,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 11,
                height: 1.4,
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Text(
                  'Learn More',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: color,
                  size: 16,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildActionRequiredSection(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Action Required', style: TextStyle(fontFamily: 'Satoshi', fontSize: 16, fontWeight: FontWeight.w800, color: _navy)),
        const SizedBox(height: 12),
        if (!vm.hasSenderDetails)
          _serviceListTile(icon: Icons.person_add, title: 'Update Sender Details', subtitle: 'Complete your profile', onTap: () => Navigator.pushNamed(context, '/update-sender-details')),
        if (!vm.hasKycDocuments)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _serviceListTile(icon: Icons.file_upload, title: 'Upload KYC', subtitle: 'Submit documents', onTap: () => Navigator.pushNamed(context, '/update-upload-documents', arguments: {'user_id': vm.currentUser.userId})),
          ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedNavIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppTheme.PrimaryColor,
      onTap: (index) {
        setState(() => _selectedNavIndex = index);
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.description_outlined), label: 'History'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
      ],
    );
  }


  // Inside DashboardScreen
  void _handleAddRecipientPressed() {
    Navigator.pushNamed(
      context,
      '/payment-details', // This is your Add Recipient screen
      arguments: {
        'user_id': vm.currentUser.userId,
        'api_key': ApiService.getApiKey(),
        'from_dashboard': true, // Add this flag
      },
    );
  }

  void _handleMoneyTransferPressed() {
    final missing = vm.getMissingItems();
    if (missing.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Incomplete Information'),
          content: Text('Please complete: ${missing.join(", ")}'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
        ),
      );
      return;
    }
    Navigator.pushNamed(context, '/money-transfer', arguments: {'userData': widget.userData, 'transferType': 'Bank Transfer'});
  }
}
