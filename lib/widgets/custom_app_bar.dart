import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:payfxglobal/utils/app_theme.dart';

class AppPrimaryAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final Color backgroundColor;
  final Color textColor;

  const AppPrimaryAppBar({
    Key? key,
    required this.title,
    this.showBackButton = true,
    this.actions,
    this.onBack,
    this.backgroundColor = Colors.white,
    this.textColor = AppTheme.TextColor,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final bool isDarkBackground = backgroundColor.computeLuminance() < 0.5;
    
    return AppBar(
      scrolledUnderElevation: 0.0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: backgroundColor,
      systemOverlayStyle: isDarkBackground 
          ? SystemUiOverlayStyle.light 
          : SystemUiOverlayStyle.light,
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: textColor,
              ),
              onPressed: onBack ??
                  () {
                    Navigator.of(context).pop();
                  },
            )
          : null,
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          fontFamily: 'Satoshi',
        ),
      ),
      actions: actions,
    );
  }
}
