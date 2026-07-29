import 'package:flutter/material.dart';
import 'package:payfxglobal/paystudy/core/constants/app_colors.dart';

class AboutUspage extends StatefulWidget {
  const AboutUspage({super.key});

  @override
  State<AboutUspage> createState() => _AboutUspageState();
}

class _AboutUspageState extends State<AboutUspage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0.0,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.TextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'About Us',
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
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Center(
                  child: Image.asset('assets/images/payfx.png', height: 100),
                ),

                const SizedBox(height: 20),

                Text(
                  'About Us',
                  style: TextStyle(
                    color: AppColors.PrimaryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Satoshi', // Add this line
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'At PayFX Global, the goal is to revolutionize cross-border payments for the Indian diaspora by offering an instant, web & app-first money transfer platform built on strong banking and card-network partnerships. The platform focuses on delivering a seamless experience end- to-end, from onboarding to settlement, so users can support loved ones with confidence.',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Satoshi',
                    fontWeight: FontWeight.w500,
                    color: AppColors.TextColor,
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Our Mission',
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'Satoshi',
                    fontWeight: FontWeight.w600,
                    color: AppColors.PrimaryColor,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'A safe, reliable and efficient international payment system is a pre-requisite for economic development. We strive to make any-where-any-currency money transfer seamless and safe by providing an efficient technology platform for all users.',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Satoshi',
                    fontWeight: FontWeight.w500,
                    color: AppColors.TextColor,
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'Our Vision',
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'Satoshi',
                    fontWeight: FontWeight.w600,
                    color: AppColors.PrimaryColor,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'Our vision is to become the most trusted bridge between a remitter and a beneficiary of any financial payment requirement across the globe. Keeping pace with dynamic changes in international payments echo-system, we shall create, curate and develop appropriate technology with due regard to legal and regulatory frameworks to make PayUni a leading global international payment solution provider.',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Satoshi',
                    fontWeight: FontWeight.w500,
                    color: AppColors.TextColor,
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  height: 150,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.TextColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [
                      _StatItem(
                        value: '180k +',
                        title: 'Happy',
                        subtitle: 'Customers',
                      ),
                      _StatItem(
                        value: '50 +',
                        title: 'Currencies',
                        subtitle: 'Offered',
                      ),
                      _StatItem(
                        value: '1M +',
                        title: 'Customers',
                        subtitle: 'Globally',
                      ),
                      _StatItem(
                        value: '30k +',
                        title: '5 - Star',
                        subtitle: 'Reviews',
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 30),

                Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Popular Countries',
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Satoshi',
                      fontWeight: FontWeight.w600,
                      color: AppColors.PrimaryColor,
                    ),
                  ),
                ),

                SizedBox(height: 20),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  children: const [
                    CountryItem(image: 'assets/flags/us.png',
                        title: 'USA'
                    ),
                    CountryItem(
                      image: 'assets/flags/canada.png',
                      title: 'Canada',
                    ),
                    CountryItem(
                      image: 'assets/flags/uk.png',
                      title: 'UK',
                    ),
                    CountryItem(
                      image: 'assets/flags/germany.png',
                      title: 'Germany',
                    ),
                    CountryItem(
                      image: 'assets/flags/newzeland.png',
                      title: 'New Zealand',
                    ),
                    CountryItem(
                      image: 'assets/flags/france.png',
                      title: 'France',
                    ),

                  ],
                ),

                SizedBox(height: 25),


                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A3A3A),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Address',
                        style: TextStyle(
                          fontSize: 26,
                          fontFamily: 'Satoshi',
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 8),


                      Container(
                        width: 120,
                        height: 2,
                        color: AppColors.PrimaryColor,
                      ),

                      const SizedBox(height: 20),

                      // Content
                      _addressText('PayFX Fintech Solutions Private Limited'),
                      _addressText('303,304, A Block, 3rd Floor,'),
                      _addressText(
                        'Raheja Center, Avinashi Rd, Near The Residency Hotel, Coimbatore.',
                      ),
                      _addressText('Pincode: 641018'),

                      const SizedBox(height: 16),

                      _linkText('Email: care@paystudy.in'),
                      _linkText('Phone: +91 9952477555'),

                      const SizedBox(height: 16),

                      _linkText(
                        'Branches: Bangalore - Coimbatore - Chennai - Delhi - Gujarat - '
                        'Hyderabad - Kochi - Mumbai - Pondicherry - Pune - Punjab - Vijayawada',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _addressText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        '• $text',
        style: const TextStyle(
          fontSize: 16,
          height: 1.5,
          fontFamily: 'Satoshi',
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _linkText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        '• $text',
        style: const TextStyle(
          fontSize: 16,
          height: 1.5,
          fontFamily: 'Satoshi',
          color: Colors.white,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

class CountryItem extends StatelessWidget {
  final String image;
  final String title;

  const CountryItem({super.key, required this.image, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(image, height: 50),
        const SizedBox(height: 15),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w600,
            color: AppColors.PrimaryColor,
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String title;
  final String subtitle;

  const _StatItem({
    required this.value,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
        ),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
        ),
      ],
    );
  }
}
