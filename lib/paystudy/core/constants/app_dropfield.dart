import 'package:flutter/material.dart';
import 'package:payfxglobal/paystudy/core/constants/app_colors.dart';

class AppDropdownField extends StatelessWidget {
  final String? hintText;
  final String? value;
  final String labelText;
  final List<String> items;
  final void Function(String?) onChanged;
  final String? Function(String?)? validator;

  const AppDropdownField({
    super.key,
    this.hintText,
    required this.labelText,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: DropdownButtonFormField<String>(
        value: value,
        style: const TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.TextColor,
        ),
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          labelStyle: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
          floatingLabelStyle: const TextStyle(
            fontFamily: 'Satoshi',
            color: AppColors.TextColor,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(
            fontFamily: 'Satoshi',
            color: Colors.grey.shade600,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.TextColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.TextColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.PrimaryColor),
          ),
        ),
        icon: Icon(
          Icons.keyboard_arrow_down,
          color: Colors.grey.shade600,
        ),
        dropdownColor: Colors.white,
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: const TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        validator: validator ??
                (value) {
              if (value == null || value.isEmpty) {
                return 'Please select an option';
              }
              return null;
            },
      ),
    );
  }
}
