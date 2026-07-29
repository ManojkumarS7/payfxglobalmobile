import 'package:flutter/material.dart';
import 'package:payfxglobal/paystudy/core/constants/app_colors.dart';
import 'package:payfxglobal/paystudy/features/application_process/application_process.dart';
import 'package:payfxglobal/paystudy/features/rmPage/rm_page.dart';
import 'package:payfxglobal/paystudy/features/support/support_page.dart';
import 'package:payfxglobal/paystudy/features/aboutus/about_usPage.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0.0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.TextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),

        title: const Text(
          'Profile',
          style: TextStyle(
            color: AppColors.TextColor,
            fontSize: 20,
            fontWeight: FontWeight.w500,
            fontFamily: 'Satoshi', // Add this line
          ),
        ),
        centerTitle: true,
      ),

      backgroundColor: Colors.white,

      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),

          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: 200,

                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.TextColor),
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,

                  children: [
                    Text(
                      'Student Name',
                      style: TextStyle(
                        color: AppColors.TextColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Satoshi',
                      ),
                    ),

                    SizedBox(height: 20),

                    Text(
                      'student****@gmail.com',
                      style: TextStyle(
                        color: AppColors.TextColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Satoshi',
                      ),
                    ),

                    SizedBox(height: 20),

                    Text(
                      'loan no: 4434 3323 4434',
                      style: TextStyle(
                        color: AppColors.TextColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Satoshi',
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade400, width: 1.5),
                ),
                child: Column(
                  children: [
                    _menuItem(
                      icon: Icons.description_outlined,
                      title: 'Track Your Application',
                      onTap: () {

                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ApplicationProcess()),
                        );

                      },
                    ),

                    _divider(),

                    _menuItem(
                      icon: Icons.call_outlined,
                      title: 'Talk To RM',
                      onTap: () {

                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => RelationShipManager()),
                        );

                      },
                    ),

                    _divider(),

                    _menuItem(
                      icon: Icons.logout,
                      title: 'Logout',
                      onTap: () {


                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade400, width: 1.5),
                ),
                child: Column(
                  children: [
                    _menuItem(
                      icon: Icons.question_mark,
                      title: 'Help And Support',
                      onTap: () {

                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SupportPage()),
                        );

                      },
                    ),

                    _divider(),

                    _menuItem(
                      icon: Icons.school,
                      title: 'About Paystudy',
                      onTap: () {


                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AboutUspage()),
                        );

                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: AppColors.PrimaryColor!, // yellow
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.TextColor),
            const SizedBox(width: 16),

            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Satoshi',
                  fontWeight: FontWeight.w500,
                  color: AppColors.TextColor,
                ),
              ),
            ),

            const Icon(
              Icons.chevron_right,
              size: 26,
              color: AppColors.TextColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Divider(thickness: 1, color: Colors.grey.shade300),
    );
  }
}
