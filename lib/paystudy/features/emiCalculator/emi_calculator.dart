import 'dart:math';
import 'package:flutter/material.dart';
import 'package:payfxglobal/paystudy/core/constants/app_colors.dart';
import 'package:payfxglobal/paystudy/core/constants/app_text_styles.dart';

class EmiCalculator extends StatefulWidget {
  const EmiCalculator({super.key});

  @override
  State<EmiCalculator> createState() => _EmiCalculatorState();
}

class _EmiCalculatorState extends State<EmiCalculator> {

  double _loanAmountSlider = 20;
  double _interestRateSlider = 12.5;
  double _tenureSlider = 14;


  double get loanAmount => _loanAmountSlider * 200000;
  double get interestRate => _interestRateSlider;
  double get tenureYears => _tenureSlider;


  double calculateEMI() {
    double principal = loanAmount;
    double rate = interestRate / 12 / 100;
    double tenure = tenureYears * 12;

    if (rate == 0) {
      return principal / tenure;
    }

    double emi = principal * rate * pow(1 + rate, tenure) / (pow(1 + rate, tenure) - 1);
    return emi;
  }

  double get monthlyEMI => calculateEMI();
  double get totalAmount => monthlyEMI * tenureYears * 12;
  double get totalInterest => totalAmount - loanAmount;

  String formatCurrency(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(2)} L';
    } else {
      return '₹${amount.toStringAsFixed(0)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0.0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.TextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'EMI Calculator',
          style: TextStyle(
            color: AppColors.TextColor,
            fontSize: 20,
            fontWeight: FontWeight.w500,
            fontFamily: 'Satoshi', // Add this line
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset('assets/images/payfx.png', height: 100),
            Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  _buildSliderSection(
                    label: 'Loan Amount',
                    value: formatCurrency(loanAmount),
                    sliderValue: _loanAmountSlider,
                    min: 1,
                    max: 100,
                    onChanged: (value) {
                      setState(() {
                        _loanAmountSlider = value;
                      });
                    },
                  ),

                  const SizedBox(height: 20),


                  _buildSliderSection(
                    label: 'Interest Rate',
                    value: interestRate.toStringAsFixed(1),
                    sliderValue: _interestRateSlider,
                    min: 1,
                    max: 20,
                    onChanged: (value) {
                      setState(() {
                        _interestRateSlider = value;
                      });
                    },
                  ),

                  const SizedBox(height: 20),


                  _buildSliderSection(
                    label: 'Loan Tenure',
                    value: '${tenureYears.toInt()} Years',
                    sliderValue: _tenureSlider,
                    min: 1,
                    max: 30,
                    onChanged: (value) {
                      setState(() {
                        _tenureSlider = value;
                      });
                    },
                  ),

                  const SizedBox(height: 40),


                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300, width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildResultRow('Monthly EMI', formatCurrency(monthlyEMI)),
                        const SizedBox(height: 16),
                        _buildResultRow('Principal Amount', formatCurrency(loanAmount)),
                        const SizedBox(height: 16),
                        _buildResultRow('Total Interest', formatCurrency(totalInterest)),
                        const SizedBox(height: 16),
                        _buildResultRow('Total Amount', formatCurrency(totalAmount)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),


                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Powered by ',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                            fontFamily: 'Satoshi',
                          ),
                        ),
                        Image.asset(
                          'assets/images/paystudy.png', // Update with your logo path
                          height: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderSection({
    required String label,
    required String value,
    required double sliderValue,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.TextColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Satoshi',
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.TextColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Satoshi',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Slider(
          thumbColor: AppColors.PrimaryColor,
          activeColor: AppColors.PrimaryColor,
          inactiveColor: Colors.grey.shade300,
          min: min,
          max: max,
          value: sliderValue,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.TextColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Satoshi',
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.TextColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Satoshi',
          ),
        ),
      ],
    );
  }
}