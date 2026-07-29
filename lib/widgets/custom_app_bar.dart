// import 'package:flutter/material.dart';
//
// class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
//   final String title;
//   final List<Widget>? actions;
//   final bool showBack;
//   final VoidCallback? onBack;
//
//   const CustomAppBar({
//     super.key,
//     required this.title,
//     this.actions,
//     this.showBack = false,
//     this.onBack,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return AppBar(
//       leading: showBack
//           ? IconButton(
//               icon: const Icon(Icons.arrow_back, color: Colors.black),
//               onPressed: onBack ?? () => Navigator.of(context).pop(),
//             )
//           : null,
//       backgroundColor: Colors.transparent,
//       elevation: 0,
//       title: Text(
//         title,
//         style: const TextStyle(
//           color: Colors.black,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//       centerTitle: false,
//       iconTheme: const IconThemeData(color: Colors.black),
//       actions: actions,
//     );
//   }
//
//   @override
//   Size get preferredSize => const Size.fromHeight(kToolbarHeight);
// }

import 'package:flutter/material.dart';
import 'package:payfxglobal/utils/app_theme.dart';
// import '../utils/app_theme.dart.dart';

class AppPrimaryAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final VoidCallback? onBack;

  const AppPrimaryAppBar({
    Key? key,
    required this.title,
    this.showBackButton = true,
    this.actions,
    this.onBack,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      scrolledUnderElevation: 0.0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false,


      leading: showBackButton
          ? IconButton(
        icon: const Icon(
          Icons.arrow_back,
          color: AppTheme.TextColor,
        ),
        onPressed: onBack ??
                () {
              Navigator.of(context).pop();
            },
      )
          : null,

      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.TextColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          fontFamily: 'Satoshi',
        ),
      ),


      actions: actions,
    );
  }
}