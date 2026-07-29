import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:payfxglobal/utils/app_theme.dart';
import 'package:payfxglobal/utils/app_constants.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? helperText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final void Function(String)? onSubmitted;
  final FocusNode? focusNode;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final EdgeInsetsGeometry? contentPadding;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onFieldSubmitted;

  const CustomTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.onTap,
    this.onSubmitted,
    this.focusNode,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.contentPadding,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTheme.labelLarge.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          onChanged: onChanged,
          onTap: onTap,
          onFieldSubmitted: onSubmitted,
          focusNode: focusNode,
          enabled: enabled,
          readOnly: readOnly,
          maxLines: maxLines,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          style: AppTheme.bodyLarge,

          decoration: InputDecoration(
            hintText: hintText,
            helperText: helperText,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppTheme.TextColor, size: 20)
                : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: enabled ? Colors.grey[50] : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              borderSide: const BorderSide(
                color: AppTheme.PrimaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              borderSide: const BorderSide(color: AppTheme.errorColor),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              borderSide: const BorderSide(
                color: AppTheme.errorColor,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            contentPadding:
                contentPadding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            counterText: '',
          ),
        ),
      ],
    );
  }
}

class PasswordTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final bool enabled;

  const PasswordTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.validator,
    this.onChanged,
    this.focusNode,
    this.textInputAction,
    this.enabled = true,
  });

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: widget.controller,
      label: widget.label,
      hintText: widget.hintText,
      prefixIcon: Icons.lock_outline,
      suffixIcon: IconButton(
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: AppTheme.TextColor,
        ),
      ),
      obscureText: _obscureText,
      validator: widget.validator,
      onChanged: widget.onChanged,
      focusNode: widget.focusNode,
      textInputAction: widget.textInputAction,
      enabled: widget.enabled,
    );
  }
}

class SearchTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final void Function(String)? onChanged;
  final void Function()? onClear;
  final FocusNode? focusNode;

  const SearchTextField({
    super.key,
    this.controller,
    this.hintText,
    this.onChanged,
    this.onClear,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      hintText: hintText ?? 'Search...',
      prefixIcon: Icons.search,
      suffixIcon: controller?.text.isNotEmpty == true
          ? IconButton(
              onPressed: () {
                controller?.clear();
                onClear?.call();
              },
              icon: const Icon(Icons.clear, color: AppTheme.TextColor),
            )
          : null,
      onChanged: onChanged,
      focusNode: focusNode,
      textInputAction: TextInputAction.search,
    );
  }
}

class AmountTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String currency;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final FocusNode? focusNode;
  final bool enabled;

  const AmountTextField({
    super.key,
    this.controller,
    this.label,
    this.currency = 'USD',
    this.validator,
    this.onChanged,
    this.focusNode,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      label: label,
      hintText: '0.00',
      prefixIcon: Icons.attach_money,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      validator: validator,
      onChanged: onChanged,
      focusNode: focusNode,
      enabled: enabled,
    );
  }
}


class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final VoidCallback? onEditingComplete;
  final bool? enabled;
  final bool isRequired;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool isPassword;
  final String? buttonText;
  final String? prefixText;
  final VoidCallback? onButtonPressed;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;           // ✅ NEW
  final ValueChanged<String>? onFieldSubmitted;     // ✅ NEW
  final FocusNode? focusNode;                       // ✅ NEW
  final List<TextInputFormatter>? inputFormatters;
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
    this.prefixIcon,
    this.suffixIcon,
    this.isPassword = false,
    this.buttonText,
    this.onButtonPressed,
    this.textCapitalization = TextCapitalization.words,
    this.textInputAction = TextInputAction.next,    // ✅ default to next
    this.onFieldSubmitted,
    this.focusNode,
    this.prefixText,
    this.inputFormatters,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Theme(
        data: Theme.of(context).copyWith(
          textSelectionTheme: TextSelectionThemeData(
            selectionColor: AppTheme.PrimaryColor.withOpacity(0.3),
            selectionHandleColor: AppTheme.PrimaryColor,
          ),
        ),
        child: TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          textCapitalization: widget.textCapitalization,
          onChanged: widget.onChanged,
          onEditingComplete: widget.onEditingComplete,
          enabled: widget.enabled,
          obscureText: widget.isPassword ? _obscureText : false,
          cursorColor: AppTheme.PrimaryColor,
          
          textInputAction: widget.textInputAction,
          inputFormatters: widget.inputFormatters,
          focusNode: widget.focusNode,
          onFieldSubmitted: widget.onFieldSubmitted ??
                  (_) => FocusScope.of(context).nextFocus(),

          style: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: (widget.enabled ?? true)
                ? AppTheme.TextColor
                : Colors.grey.shade500,
          ),

          decoration: InputDecoration(
            labelText:
            widget.isRequired ? "${widget.labelText} *" : widget.labelText,
            hintText: widget.hintText,

            prefixText: widget.prefixText,
            prefixStyle: const TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.TextColor,
            ),

            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, color: AppTheme.PrimaryColor)
                : null,

            suffixIcon: widget.isPassword
                ? IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () => setState(() => _obscureText = !_obscureText),
            )
                : widget.buttonText != null
                ? TextButton(
              onPressed: widget.onButtonPressed,
              child: Text(
                widget.buttonText!,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.PrimaryColor,
                ),
              ),
            )
                : widget.suffixIcon,

            labelStyle: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),

            filled: true,
            fillColor:
            (widget.enabled ?? true) ? Colors.white : Colors.grey.shade100,

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
              BorderSide(color: AppTheme.TextColor.withOpacity(0.3)),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.PrimaryColor),
            ),
          ),

          validator: widget.validator ??
                  (value) {
                if (widget.isRequired &&
                    (widget.enabled ?? true) &&
                    (value == null || value.isEmpty)) {
                  return 'This field is required';
                }
                return null;
              },
        ),
      ),
    );
  }
}


class AadhaarInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue,
      TextEditingValue newValue,) {
    // Remove spaces
    String text = newValue.text.replaceAll(' ', '');

    // Limit to 12 digits
    if (text.length > 12) {
      text = text.substring(0, 12);
    }

    // Add spaces after every 4 digits
    String formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        formatted += ' ';
      }
      formatted += text[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
