import 'package:flutter/material.dart';

/// Helper mixin to prevent app from closing on back button press
/// Use this mixin on all StatefulWidget screens that should not close the app
mixin SafeNavigationMixin<T extends StatefulWidget> on State<T> {
  /// Override this method in your screen to define safe back navigation
  /// For example: navigate to dashboard instead of closing
  void onSafeBack(BuildContext context) {
    // Default: just pop if there's a route to go back to
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  /// Wrap your Scaffold with PopScope to prevent app closure
  /// Usage:
  /// return PopScope(
  ///   canPop: false,
  ///   onPopInvokedWithResult: (didPop, result) {
  ///     if (didPop) return;
  ///     onSafeBack(context);
  ///   },
  ///   child: Scaffold(...),
  /// );
}

/// Global function to navigate back safely
/// Use this in any back button or navigation handler
void navigateBackSafely(
  BuildContext context, {
  required String fallbackRoute,
  Map<String, dynamic>? fallbackArgs,
}) {
  if (Navigator.canPop(context)) {
    Navigator.pop(context);
  } else {
    // Fallback to specified route if no route to pop
    Navigator.pushReplacementNamed(
      context,
      fallbackRoute,
      arguments: fallbackArgs ?? {},
    );
  }
}

/// Safe back button builder widget
/// Wraps Scaffold with PopScope protection
class SafeScaffold extends StatelessWidget {
  final AppBar? appBar;
  final Widget body;
  final Color? backgroundColor;
  final FloatingActionButton? floatingActionButton;
  final String? fallbackRoute;
  final Map<String, dynamic>? fallbackArgs;
  final bool preventBackButtonClose;

  const SafeScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.backgroundColor,
    this.floatingActionButton,
    this.fallbackRoute,
    this.fallbackArgs,
    this.preventBackButtonClose = true,
  });

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
    );

    if (!preventBackButtonClose) {
      return scaffold;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        navigateBackSafely(
          context,
          fallbackRoute: fallbackRoute ?? '/dashboard',
          fallbackArgs: fallbackArgs,
        );
      },
      child: scaffold,
    );
  }
}
