import 'package:flutter/material.dart';
import 'package:payfxglobal/paystudy/core/constants/app_colors.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final VoidCallback? onEditingComplete;
  final bool? enabled;
  final bool isRequired;
  final TextCapitalization? textCapitalization;


  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const AppTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.onChanged,
    this.keyboardType,
    this.validator,
    this.onEditingComplete,
    this.enabled,
    this.isRequired = false,
    this.buttonText,
    this.onButtonPressed,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: TextFormField(
        textCapitalization: textCapitalization!,
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        onEditingComplete: onEditingComplete,
        enabled: enabled,
        cursorColor: AppColors.PrimaryColor,
        style: TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: (enabled ?? true)
              ? AppColors.TextColor
              : Colors.grey.shade500,
        ),
        decoration: InputDecoration(
          labelText: isRequired ? "$labelText *" : labelText,
          hintText: hintText,

          suffixIcon: buttonText != null
              ? TextButton(
            onPressed: onButtonPressed,
            child: Text(
              buttonText!,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.PrimaryColor,
              ),
            ),
          )
              : null,

          labelStyle: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
          filled: true,
          fillColor:
          (enabled ?? true) ? Colors.white : Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.TextColor.withOpacity(0.3)),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
            const BorderSide(color: AppColors.PrimaryColor),
          ),
        ),
        validator: validator ??
                (value) {
              if (isRequired &&
                  (enabled ?? true) &&
                  (value == null || value.isEmpty)) {
                return 'This field is required';
              }
              return null;
            },
      ),
    );
  }
}
