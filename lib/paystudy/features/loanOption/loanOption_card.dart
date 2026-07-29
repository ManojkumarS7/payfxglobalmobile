import 'package:flutter/material.dart';
import 'package:payfxglobal/paystudy/core/constants/app_colors.dart';

class LoanOptionCard extends StatelessWidget {
  final String optionTitle;
  final bool isSelected;
  final VoidCallback onTap;

  final String loanAmount;
  final String interestRate;
  final String duringEmi;
  final String afterEmi;
  final String bank;
  final bool isLeastTwo;

  const LoanOptionCard({
    super.key,
    required this.optionTitle,
    required this.isSelected,
    required this.onTap,
    required this.loanAmount,
    required this.interestRate,
    required this.duringEmi,
    required this.afterEmi,
    required this.bank,
    this.isLeastTwo = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected
              ? AppColors.PrimaryColor?.withOpacity(0.05)
              : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.PrimaryColor! : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            // HEADER CONTAINER
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isLeastTwo
                    ? const Color.fromRGBO(62, 224, 156, 1)
                    : const Color.fromRGBO(220, 255, 218, 1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  Text(
                    optionTitle,
                    style: const TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppColors.TextColor,
                    ),
                  ),
                  const Spacer(),
                  _checkCircle(),
                ],
              ),
            ),

            // CONTENT CONTAINER
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _row(
                    'Loan Amount',
                    loanAmount ,
                    'Interest Rate',
                    interestRate,
                  ),
                  const SizedBox(height: 20),
                  _row(
                    'During Course EMI',
                    duringEmi,
                    'After Course EMI',
                    afterEmi,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.PrimaryColor
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Bank : $bank',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.TextColor,
                      ),
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

  Widget _checkCircle() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? AppColors.PrimaryColor : Colors.grey.shade400,
      ),
      child: const Icon(Icons.check, size: 20, color: Colors.white),
    );
  }

  Widget _row(String l1, String v1, String l2, String v2) {
    return Row(
      children: [
        Expanded(child: _column(l1, v1)),
        Expanded(child: _column(l2, v2)),
      ],
    );
  }

  Widget _column(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppColors.TextColor,
          ),
        ),
      ],
    );
  }
}
