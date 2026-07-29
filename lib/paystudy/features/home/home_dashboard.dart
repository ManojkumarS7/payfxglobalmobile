import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payfxglobal/paystudy/core/constants/app_colors.dart';
import 'package:payfxglobal/paystudy/features/documents/documents_UploadPage.dart';
import 'package:payfxglobal/paystudy/features/formpage/studentform.dart';
import 'package:payfxglobal/paystudy/features/application_process/application_process.dart';
import 'package:payfxglobal/paystudy/features/rmPage/rm_page.dart';
import 'package:payfxglobal/paystudy/features/emiCalculator/emi_calculator.dart';
import 'package:payfxglobal/paystudy/core/providers/loanProvider/loan_provider.dart';
import 'package:payfxglobal/paystudy/core/providers/bottomBar/bottom_nav_provider.dart';
import 'package:payfxglobal/paystudy/core/constants/dashboard.dart';
import 'package:payfxglobal/widgets/custom_app_bar.dart';


class PaystudyDashboardScreen extends ConsumerWidget {

  const PaystudyDashboardScreen ({Key? key}) : super(key: key);



  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loanAsync = ref.watch(loanNoProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      
      appBar: AppPrimaryAppBar(title: 'Education Loan'),
      body: SafeArea(
        
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Image.asset('assets/images/payfx.png', height: 100),
                    const SizedBox(height: 20),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          // Row 1
                          Row(
                            children: [
                              Expanded(
                                child: _DashboardCard(
                                  icon: Icons.school_outlined,
                                  title: 'Check Eligibility',
                                  subtitle: 'Find out your qualify',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => StudentFormPage(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: _DashboardCard(
                                  icon: Icons.search,
                                  title: 'Track Application',
                                  subtitle: 'View your status',
                                  onTap: () {
                                    // ref.read(bottomNavProvider.notifier).state = 1;

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ApplicationProcess(),
                                      ),
                                    );

                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 40),

                          Row(
                            children: [
                              Expanded(
                                child: _DashboardCard(
                                  icon: Icons.support_agent_outlined,
                                  title: 'Talk To RM',
                                  subtitle: 'Your Relationship Manager',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => RelationShipManager(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: _DashboardCard(
                                  icon: Icons.calculate_outlined,
                                  title: 'EMI Calculator',
                                  subtitle: 'Calculate your monthly EMI',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EmiCalculator(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 40),

                          loanAsync.when(
                            data: (loanNo) {
                              if (loanNo == null) return const SizedBox();

                              return Column(
                                children: [
                                  Center(
                                    child: SizedBox(
                                      width: MediaQuery.of(context).size.width * 0.48,
                                      child: _DashboardCard(
                                        icon: Icons.upload_file_outlined,
                                        title: 'Documents',
                                        subtitle: 'Upload Your Documents',
                                        onTap: () {
                                          // ref.read(bottomNavProvider.notifier).state = 2;

                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => DocumentsUploadpage(),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                ],
                              );
                            },
                            loading: () => const CircularProgressIndicator(),
                            error: (e, _) => const SizedBox(),
                          ),



                        ],
                      ),
                    ),

                    const SizedBox(height: 50),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Powered by ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Image.asset('assets/images/paystudy.png', height: 16),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.PrimaryColor,
              offset: const Offset(1.8, 2),
              spreadRadius: 0.3,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 30, color: AppColors.TextColor),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Container(height: 2, width: 40, color: AppColors.PrimaryColor),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
