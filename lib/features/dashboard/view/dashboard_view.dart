
import 'package:flutter/material.dart';
import 'package:payfxglobal/features/auth/view/login_screen.dart' hide LoadingOverlay;
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

  // ---- Palette -------------------------------------------------------------
  static const Color _navy =  AppTheme.PrimaryColor;
  static const Color _ink = Color(0xFF0B1B3A);
  static const Color _accent = Color(0xFFFFC72C); // primary yellow
  static const Color _bg = Color(0xFFF5F7FB);
  static const String _font = 'Satoshi';

  int _selectedNavIndex = 0;
  bool _goingRight = true;

  final ScrollController _scroll = ScrollController();
  final ValueNotifier<double> _offset = ValueNotifier<double>(0);
  static const double _heroExtent = 270;
  int _offerCounter = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() => _offset.value = _scroll.hasClients ? _scroll.offset : 0);
    ApiService.initializeApiKey();
    SessionManager.updateLastActive();
    vm = DashboardViewModel(service: DashboardService());
    vm.initialize(widget.userData);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      LoginScreen.askBiometricPermission(context);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _offset.dispose();
    super.dispose();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _setTab(int i) {
    if (i == _selectedNavIndex) return;
    setState(() {
      _goingRight = i > _selectedNavIndex;
      _selectedNavIndex = i;
    });
  }

  // ---- Build ---------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
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
              backgroundColor: _bg,
              body: SafeArea(
                bottom: false,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 380),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, anim) {
                    final dx = _goingRight ? 0.12 : -0.12;
                    return FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(begin: Offset(dx, 0), end: Offset.zero).animate(anim),
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey(_selectedNavIndex),
                    child: _buildBody(),
                  ),
                ),
              ),
              bottomNavigationBar: _buildBottomNavBar(),
            );
          },
        );
      },
    );
  }

  Widget _buildBody() {
    switch (_selectedNavIndex) {
      case 1:
        return TransactionHistoryScreen(userId: vm.currentUser.userId);
      case 2:
        return ProfileScreen(user: vm.currentUser);
      default:
        return _buildHomeTab();
    }
  }

  // ---- Home tab (collapsing hero) ------------------------------------------
  Widget _buildHomeTab() {
    final isKycActionNeeded = !vm.hasSenderDetails || !vm.hasKycDocuments;
    int i = 0; // stagger index

    return RefreshIndicator(
      color: AppTheme.PrimaryColor,
      onRefresh: () => vm.refresh(widget.userData),
      child: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          // Pinned top bar (stays), gets a compact "Send" pill once hero is gone
          SliverPersistentHeader(
            pinned: true,
            delegate: _BoxHeaderDelegate(
              extent: 68,
              builder: (ctx, shrink, overlaps) => ValueListenableBuilder<double>(
                valueListenable: _offset,
                builder: (_, off, __) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: _bg,
                    boxShadow: off > 8
                        ? [BoxShadow(color: _navy.withOpacity(0.08), blurRadius: 14, offset: const Offset(0, 6))]
                        : const [],
                  ),
                  alignment: Alignment.center,
                  child: _buildTopBar(showCompact: off > _heroExtent * 0.55),
                ),
              ),
            ),
          ),

          // Hero collapses: fades, shrinks and slides up as you scroll
          SliverPersistentHeader(
            delegate: _HeroCollapseDelegate(
              extent: _heroExtent,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: _FadeSlide(index: i++, child: _buildHeroCard()),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _FadeSlide(index: i++, child: _buildQuickActionsRow()),
                if (isKycActionNeeded) ...[
                  const SizedBox(height: 24),
                  _FadeSlide(index: i++, child: _buildActionRequiredSection()),
                ],
                const SizedBox(height: 28),
                _FadeSlide(index: i++, child: _sectionTitle('Services')),
                const SizedBox(height: 12),
                _FadeSlide(index: i++, child: _buildServicesList()),
                const SizedBox(height: 24),
                _FadeSlide(index: i++, child: _buildEducationLoanPromo()),
                const SizedBox(height: 28),
                _FadeSlide(index: i++, child: _sectionTitle('Study abroad accounts')),
                const SizedBox(height: 12),
                _FadeSlide(index: i++, child: _buildGicAndBlockedAccountRow()),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
    text,
    style: const TextStyle(fontFamily: _font, fontSize: 18, fontWeight: FontWeight.w800, color: _ink, letterSpacing: -0.2),
  );

  // ---- Top bar -------------------------------------------------------------
  Widget _buildTopBar({bool showCompact = false}) {
    return Row(
      children: [
        Image.asset(
          'assets/images/payfx.png',
          height: 150,
          width: 150,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Text(
            'PayFX',
            style: TextStyle(
              fontFamily: _font,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _navy,
            ),
          ),
        ),
        const Spacer(),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          transitionBuilder: (c, a) => FadeTransition(
            opacity: a,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0.4, 0), end: Offset.zero).animate(a),
              child: c,
            ),
          ),
          child: showCompact
              ? Padding(
            key: const ValueKey('compact'),
            padding: const EdgeInsets.only(right: 10),
            child: _Pressable(
              onTap: _handleMoneyTransferPressed,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(22)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.north_east_rounded, size: 15, color: _ink),
                    SizedBox(width: 5),
                    Text('Send',
                        style: TextStyle(fontFamily: _font, fontSize: 13, fontWeight: FontWeight.w800, color: _ink)),
                  ],
                ),
              ),
            ),
          )
              : const SizedBox.shrink(key: ValueKey('none')),
        ),
        _Pressable(
          onTap: () => Navigator.pushNamed(context, '/notifications'),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: _navy.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.notifications_none_rounded, color: _navy, size: 22),
          ),
        ),
        const SizedBox(width: 10),
        _Pressable(
          onTap: () => _setTab(2),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(shape: BoxShape.circle, color: _accent),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: _navy,
              child: Text(
                vm.initialsFromName(vm.currentUser.fullName),
                style: const TextStyle(fontFamily: _font, color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---- Hero card (greeting + quick transfer) -------------------------------
  Widget _buildHeroCard() {
    return SizedBox(
      height: _heroExtent - 16,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: _navy.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: _heroBody(),
      ),
    );
  }

  Widget _heroBody() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(color: Colors.white),
        child: Stack(
          children: [
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(shape: BoxShape.circle, color: _accent.withOpacity(0.35)),
              ),
            ),
            Positioned(
              right: 30,
              bottom: -60,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(shape: BoxShape.circle, color: _accent.withOpacity(0.15)),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('${_greeting()}',
                        style: TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: _accent.withOpacity(0.25), borderRadius: BorderRadius.circular(20)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded, size: 14, color: Color(0xFF0F7B4F)),
                          SizedBox(width: 5),
                          Text('Verified', style: TextStyle(fontFamily: _font, fontSize: 11, fontWeight: FontWeight.w700, color: _ink)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  vm.currentUser.fullName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: _font, fontSize: 20, fontWeight: FontWeight.w800, color: _ink, letterSpacing: -0.5),
                ),
                const SizedBox(height: 16),
                const Text('Send money abroad',
                    style: TextStyle(fontFamily: _font, fontSize: 17, fontWeight: FontWeight.w700, color: _ink)),
                const SizedBox(height: 4),
                Text('Fast, secure & low-fee global transfers',
                    style: TextStyle(fontFamily: _font, fontSize: 13, color: Colors.grey.shade600)),
                const SizedBox(height: 11),
                _Pressable(
                  onTap: _handleMoneyTransferPressed,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(30)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.north_east_rounded, size: 18, color: _ink),
                        SizedBox(width: 8),
                        Text('Send money', style: TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w800, color: _ink)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---- Quick actions -------------------------------------------------------
  Widget _buildQuickActionsRow() {
    return Row(
      children: [
        _quickActionIcon('Add recipient', Icons.person_add_alt_1_rounded, _handleAddRecipientPressed),
        _quickActionIcon('History', Icons.history_rounded, () => _setTab(1)),
        _quickActionIcon('Rates', Icons.show_chart_rounded, () => Navigator.pushNamed(context, '/currency-rates')),
        _quickActionIcon('Support', Icons.headset_mic_rounded, () => Navigator.pushNamed(context, '/support')),
      ],
    );
  }

  Widget _quickActionIcon(String label, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: _Pressable(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: _navy.withOpacity(0.07), blurRadius: 14, offset: const Offset(0, 6))],
              ),
              child: Icon(icon, color: AppTheme.PrimaryColor, size: 26),
            ),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: _font, fontSize: 11.5, fontWeight: FontWeight.w700, color: _ink)),
          ],
        ),
      ),
    );
  }

  // ---- Services ------------------------------------------------------------
  Widget _buildServicesList() {
    return Column(
      children: [
        _serviceListTile(
          icon: Icons.send_rounded,
          title: 'Money Transfer',
          subtitle: 'Fast and secure global transfers',
          tint: const Color(0xFFE6F0FF),
          onTap: _handleMoneyTransferPressed,
        ),
        const SizedBox(height: 12),
        _serviceListTile(
          icon: Icons.school_rounded,
          title: 'Education Loan',
          subtitle: 'Supporting your academic dreams',
          tint: const Color(0xFFFFF1DB),
          onTap: () => Navigator.pushNamed(context, '/education-loan'),
        ),
        const SizedBox(height: 12),
        _serviceListTile(
          icon: Icons.lock_outline_rounded,
          title: 'GIC & Blocked Account',
          subtitle: 'Open your accounts instantly',
          tint: const Color(0xFFE5F8E0),
          onTap: () => Navigator.pushNamed(context, '/account-opening'),
        ),
      ],
    );
  }

  Widget _serviceListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color tint,
    VoidCallback? onTap,
  }) {
    return _Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: _navy.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: _navy, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontFamily: _font, fontSize: 15, fontWeight: FontWeight.w800, color: _ink)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontFamily: _font, fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: _bg, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _navy),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Education loan promo -----------------------------------------------
  Widget _buildEducationLoanPromo() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFE27A), Color(0xFFFFC72C)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -14,
              child: Icon(Icons.school_rounded, size: 120, color: _ink.withOpacity(0.07)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: _ink.withOpacity(0.10), borderRadius: BorderRadius.circular(20)),
                  child: const Text('STUDY ABROAD',
                      style: TextStyle(fontFamily: _font, fontSize: 10, fontWeight: FontWeight.w800, color: _ink, letterSpacing: 0.8)),
                ),
                const SizedBox(height: 12),
                const Text('Education Loan',
                    style: TextStyle(fontFamily: _font, fontSize: 22, fontWeight: FontWeight.w800, color: _ink, letterSpacing: -0.4)),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(right: 70),
                  child: Text(
                    'Hassle-free international education loans, from application to disbursal.',
                    style: TextStyle(fontFamily: _font, fontSize: 13, height: 1.4, color: _ink.withOpacity(0.75)),
                  ),
                ),
                const SizedBox(height: 16),
                _Pressable(
                  onTap: () => Navigator.pushNamed(context, '/education-loan'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(color: _ink, borderRadius: BorderRadius.circular(30)),
                    child: const Text('Check eligibility',
                        style: TextStyle(fontFamily: _font, fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---- GIC / Blocked account ----------------------------------------------
  Widget _buildGicAndBlockedAccountRow() {
    return Row(
      children: [
        Expanded(
          child: _infoCard(
            title: 'GIC',
            subtitle: 'Secure investment for Canada study visa',
            flag: 'assets/flags/ca.png',
            icon: Icons.shield_outlined,
            onTap: () => _showAccountDetailSheet('GIC'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _infoCard(
            title: 'Blocked Account',
            subtitle: 'Open your blocked account for Germany',
            flag: 'assets/flags/germany.png',
            icon: Icons.lock_outline_rounded,
            onTap: () => _showAccountDetailSheet('Blocked Account'),
          ),
        ),
      ],
    );
  }

  Widget _infoCard({
    required String title,
    required String subtitle,
    required String flag,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return _Pressable(
      onTap: onTap,
      child: Container(
        height: 188,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: _navy.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(14)),
                  child: Icon(icon, color: _navy, size: 20),
                ),
                const Spacer(),
                ClipOval(child: Image.asset(flag, width: 26, height: 26, fit: BoxFit.cover)),
              ],
            ),
            const Spacer(),
            Text(title, style: const TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: _font, fontSize: 11.5, height: 1.4, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),
            const Row(
              children: [
                Text('Learn more', style: TextStyle(fontFamily: _font, color: _navy, fontSize: 12, fontWeight: FontWeight.w800)),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, color: _navy, size: 15),
              ],
            ),
          ],
        ),
      ),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.fromLTRB(24, 14, 24, 24 + MediaQuery.of(context).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: _navy.withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
                  child: Icon(isGic ? Icons.shield_outlined : Icons.lock_outline_rounded, color: _navy, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    isGic ? 'GIC (Canada)' : 'Blocked Account (Germany)',
                    style: const TextStyle(fontFamily: _font, fontSize: 20, fontWeight: FontWeight.w800, color: _ink),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              isGic
                  ? 'Guaranteed Investment Certificate (GIC) is a mandatory requirement for international students applying for a Canada Study Permit under the SDS (Student Direct Stream) program.'
                  : 'A Blocked Account is a special type of bank account for international students and job seekers in Germany to prove they have enough funds to cover their living expenses.',
              style: TextStyle(fontFamily: _font, fontSize: 14, color: Colors.grey.shade700, height: 1.5),
            ),
            const SizedBox(height: 20),
            const Text('What we offer',
                style: TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
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
            const SizedBox(height: 24),
            _Pressable(
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/account-opening');
              },
              child: Container(
                width: double.infinity,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(30)),
                child: Text(
                  isGic ? 'Open your GIC account' : 'Open blocked account',
                  style: const TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferItem(String text) {
    return _FadeSlide(index: _offerCounter++ % 3 + 2, child: Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 1),
            width: 20,
            height: 20,
            decoration: const BoxDecoration(color: _accent, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: _ink, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(fontFamily: _font, fontSize: 13, height: 1.4, color: Colors.grey.shade700)),
          ),
        ],
      ),
    ));
  }

  // ---- Action required -----------------------------------------------------


  Widget _buildActionRequiredSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFE0A3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_rounded, color: Color(0xFFE59A00), size: 20),
              SizedBox(width: 8),
              Text('Action required',
                  style: TextStyle(fontFamily: _font, fontSize: 15, fontWeight: FontWeight.w800, color: _ink)),
            ],
          ),
          const SizedBox(height: 12),
          if (!vm.hasSenderDetails)
            _serviceListTile(
              icon: Icons.person_add_rounded,
              title: 'Update Sender Details',
              subtitle: 'Complete your profile',
              tint: const Color(0xFFE6F0FF),
              onTap: () => Navigator.pushNamed(context, '/update-sender-details'),
            ),
          if (!vm.hasKycDocuments)
            Padding(
              padding: EdgeInsets.only(top: vm.hasSenderDetails ? 0 : 12),
              child: _serviceListTile(
                icon: Icons.file_upload_rounded,
                title: 'Upload KYC',
                subtitle: 'Submit documents',
                tint: const Color(0xFFE5F8E0),
                onTap: () => Navigator.pushNamed(context, '/update-upload-documents', arguments: {'user_id': vm.currentUser.userId}),
              ),
            ),
        ],
      ),
    );
  }

  // ---- Bottom nav: white sheet, bubble indicator, outline -> filled icons --
  Widget _buildBottomNavBar() {
    const items = [
      (Icons.home_outlined, Icons.home_rounded, 'Home'),
      (Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Payments'),
      (Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: _navy.withOpacity(0.10), blurRadius: 24, offset: const Offset(0, -6))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Row(
            children: List.generate(items.length, (index) {
              final selected = index == _selectedNavIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _setTab(index),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        width: selected ? 60 : 36,
                        height: 34,
                        decoration: BoxDecoration(
                          color: selected ? _navy.withOpacity(0.10) : Colors.transparent,
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: AnimatedScale(
                          scale: selected ? 1.1 : 1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutBack,
                          child: Icon(
                            selected ? items[index].$2 : items[index].$1,
                            size: 24,
                            color: selected ? _navy : Colors.grey.shade500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 250),
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 11.5,
                          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                          color: selected ? _navy : Colors.grey.shade500,
                        ),
                        child: Text(items[index].$3),
                      ),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: selected ? 5 : 0,
                        height: selected ? 5 : 0,
                        decoration: const BoxDecoration(color: _accent, shape: BoxShape.circle),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ---- Handlers (unchanged logic) -----------------------------------------
  void _handleAddRecipientPressed() {
    Navigator.pushNamed(
      context,
      '/payment-details',
      arguments: {
        'user_id': vm.currentUser.userId,
        'api_key': ApiService.getApiKey(),
        'from_dashboard': true,
      },
    );
  }

  void _handleMoneyTransferPressed() {
    final missing = vm.getMissingItems();
    if (missing.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Incomplete Information', style: TextStyle(fontFamily: _font, fontWeight: FontWeight.w800)),
          content: Text('Please complete: ${missing.join(", ")}', style: const TextStyle(fontFamily: _font)),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
        ),
      );
      return;
    }
    Navigator.pushNamed(context, '/money-transfer', arguments: {'userData': widget.userData, 'transferType': 'Bank Transfer'});
  }
}

// ============================================================================
// Animation helpers
// ============================================================================

/// Fade + slide-up entrance. Higher [index] = slightly longer animation,
/// which produces a staggered cascade down the page.
class _FadeSlide extends StatelessWidget {
  final Widget child;
  final int index;

  const _FadeSlide({required this.child, this.index = 0});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 450 + index * 90),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, 28 * (1 - value)), child: child),
      ),
      child: child,
    );
  }
}

/// Tap target with a subtle press-scale feedback.
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
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Fixed-height pinned header builder.
class _BoxHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double extent;
  final Widget Function(BuildContext, double, bool) builder;

  _BoxHeaderDelegate({required this.extent, required this.builder});

  @override
  double get minExtent => extent;
  @override
  double get maxExtent => extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      builder(context, shrinkOffset, overlapsContent);

  @override
  bool shouldRebuild(covariant _BoxHeaderDelegate old) => true;
}

/// Hero banner that collapses to zero height while fading, scaling and
/// drifting upward as the page scrolls.
class _HeroCollapseDelegate extends SliverPersistentHeaderDelegate {
  final double extent;
  final Widget child;

  _HeroCollapseDelegate({required this.extent, required this.child});

  @override
  double get minExtent => 0;
  @override
  double get maxExtent => extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final t = (shrinkOffset / extent).clamp(0.0, 1.0);
    return ClipRect(
      child: Opacity(
        opacity: (1 - t * 1.25).clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 1 - 0.12 * t,
          alignment: Alignment.topCenter,
          child: Transform.translate(
            offset: Offset(0, -shrinkOffset * 0.15),
            child: OverflowBox(
              alignment: Alignment.topCenter,
              minHeight: extent,
              maxHeight: extent,
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _HeroCollapseDelegate old) => true;
}
