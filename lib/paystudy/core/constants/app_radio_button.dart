import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppRadioTile<T> extends StatelessWidget {
  final T value;
  final T groupValue;
  final String title;
  final String? subtitle;
  final ValueChanged<T?> onChanged;

  const AppRadioTile({
    super.key,
    required this.value,
    required this.groupValue,
    required this.title,
    this.subtitle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Radio<T>(
          value: value,
          groupValue: groupValue,
          onChanged: onChanged,
          activeColor: AppColors.PrimaryColor,
        ),

        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(value),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  title,
                  style: AppTextStyles.button,
                ),

                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      subtitle!,
                      style: AppTextStyles.body.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ),

              ],
            ),
          ),
        )
      ],
    );
  }
}