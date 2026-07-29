import 'package:flutter/material.dart';
import 'package:payfxglobal/paystudy/features/home/home_dashboard.dart';
import 'package:payfxglobal/paystudy/features/application_process/application_process.dart';
import 'package:payfxglobal/paystudy/features/documents/documents_UploadPage.dart';
import 'package:payfxglobal/paystudy/features/profile/profile_Page.dart';
import 'app_colors.dart';
import 'package:payfxglobal/paystudy/core/providers/bottomBar/bottom_nav_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class MainDashboard extends ConsumerWidget {

  final int initialIndex;

  const MainDashboard({super.key, this.initialIndex = 0});



  final List<Widget> _pages =  const [
    PaystudyDashboardScreen(),
    ApplicationProcess(),
    DocumentsUploadpage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final currentIndex = ref.watch(bottomNavProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: AppColors.PrimaryColor,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(ref,Icons.home, 'Home', 0, currentIndex),
            _buildNavItem(ref,Icons.description_outlined, 'Application', 1, currentIndex),
            _buildNavItem(ref,Icons.folder_outlined, 'Documents', 2, currentIndex),
            // _buildNavItem(ref,Icons.person_outline, 'Profile', 3, currentIndex),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(WidgetRef ref, IconData icon, String label, int index, int currentIndex) {
    final isActive = currentIndex == index;

    return GestureDetector(
      onTap: () {
     ref.read(bottomNavProvider.notifier).state = index;
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? AppColors.TextColor : Colors.grey[400],
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? AppColors.TextColor : Colors.grey[400],
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
