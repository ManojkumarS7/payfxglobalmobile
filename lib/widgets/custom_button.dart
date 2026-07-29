import 'package:flutter/material.dart';
import 'package:payfxglobal/utils/app_theme.dart';
import 'package:payfxglobal/utils/app_constants.dart';
import 'package:payfxglobal/widgets/custom_loading_indicator.dart';



class AppPrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String title;
  final bool loading;
  final double height;
  final double borderRadius;

  const AppPrimaryButton({
    Key? key,
    required this.title,
    required this.onPressed,
    this.loading = false,
    this.height = 56,
    this.borderRadius = 28,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.PrimaryColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: BorderSide(
              color: AppTheme.PrimaryColor!,
              width: 2,
            ),
          ),
        ),
        child: loading
            ? const SizedBox(
          height: 22,
          width: 22,
          // child: CircularProgressIndicator(strokeWidth: 2),
         child:  ButtonLoader(),
        )
            : Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontFamily: 'Satoshi',
            fontWeight: FontWeight.w500,
            color: AppTheme.TextColor,
          ),
        ),
      ),
    );
  }
}


class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final IconData? icon;
  final Gradient? gradient;
  final double? width;
  final double height;
  final EdgeInsetsGeometry? padding;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.icon,
    this.gradient,
    this.width,
    this.height = AppConstants.buttonHeight,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final bool enabled = isEnabled && onPressed != null && !isLoading;

    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: gradient != null
          ? BoxDecoration(
              gradient: enabled ? gradient : null,
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              border: borderColor != null
                  ? Border.all(color: borderColor!)
                  : null,
            )
          : null,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: gradient != null
              ? Colors.transparent
              : (backgroundColor ?? AppTheme.PrimaryColor),
          foregroundColor: textColor ?? Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          disabledForegroundColor: Colors.grey[600],
          elevation: gradient != null ? 0 : 2,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            side: borderColor != null && gradient == null
                ? BorderSide(color: borderColor!)
                : BorderSide.none,
          ),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    textColor ?? Colors.white,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: AppTheme.labelLarge.copyWith(
                      color: textColor ?? Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class OutlinedCustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final Color? borderColor;
  final Color? textColor;
  final IconData? icon;
  final double? width;
  final double height;

  const OutlinedCustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.borderColor,
    this.textColor,
    this.icon,
    this.width,
    this.height = AppConstants.buttonHeight,
  });

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isEnabled: isEnabled,
      backgroundColor: Colors.transparent,
      textColor: textColor ?? AppTheme.PrimaryColor,
      borderColor: borderColor ?? AppTheme.PrimaryColor,
      icon: icon,
      width: width,
      height: height,
    );
  }
}

// class AccentButton extends StatelessWidget {
//   final String text;
//   final VoidCallback? onPressed;
//   final bool isLoading;
//   final bool isEnabled;
//   final IconData? icon;
//   final double? width;
//   final double height;
//
//   const AccentButton({
//     super.key,
//     required this.text,
//     this.onPressed,
//     this.isLoading = false,
//     this.isEnabled = true,
//     this.icon,
//     this.width,
//     this.height = AppConstants.buttonHeight,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return CustomButton(
//       text: text,
//       onPressed: onPressed,
//       isLoading: isLoading,
//       isEnabled: isEnabled,
//       gradient: AppTheme.accentGradient,
//       textColor: Colors.white,
//       icon: icon,
//       width: width,
//       height: height,
//     );
//   }
// }

class IconCustomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;

  const IconCustomButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.backgroundColor,
    this.iconColor,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.PrimaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(size / 4),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: iconColor ?? AppTheme.PrimaryColor,
          size: size * 0.5,
        ),
        tooltip: tooltip,
      ),
    );
  }
}
