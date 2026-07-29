import 'package:flutter/material.dart';

class AppTheme {
  // // Colors - Updated with official PayUni branding
  // static const Color primaryColor = Color.fromARGB(255, 235, 202, 83); // PayUni deep blue
  // static const Color secondaryColor = Color(0xFF3B82F6); // PayUni light blue
  // static const Color accentColor = Color(
  //   0xFFF59E0B,
  // ); // PayUni orange (CTA buttons)
  // static const Color payuniRed = Color(
  //   0xFFE53E3E,
  // ); // Official PayUni red from logo
  // static const Color successColor = Color(0xFF10B981); // Green for success
  static const Color errorColor = Color(0xFFEF4444); // Red for errors
  // static const Color warningColor = Color(0xFFF59E0B); // Orange for warnings
  static const Color backgroundColor = Color(
    0xFFFAFBFC,
  ); // Very light blue-gray
  // static const Color surfaceColor = Colors.white;
  // static const Color textPrimary = Color(
  //   0xFF2D3748,
  // ); // Dark gray (matching logo text)
  // static const Color textSecondary = Color(0xFF6B7280); // Medium gray
  // static const Color dividerColor = Color(0xFFE5E7EB);
  //
  // // PayUni Brand Gradients
  // static const LinearGradient primaryGradient = LinearGradient(
  //   colors: [primaryColor, secondaryColor],
  //   begin: Alignment.topLeft,
  //   end: Alignment.bottomRight,
  // );
  //
  // static const LinearGradient accentGradient = LinearGradient(
  //   colors: [Color(0xFFF59E0B), Color(0xFFEAB308)],
  //   begin: Alignment.topLeft,
  //   end: Alignment.bottomRight,
  // );
  //
  // static const LinearGradient successGradient = LinearGradient(
  //   colors: [successColor, Color(0xFF059669)],
  //   begin: Alignment.topLeft,
  //   end: Alignment.bottomRight,
  // );
  // #f5a623
  static const Color PrimaryColor = Color(0xFFF9C63D);

  // static const Color PrimaryColor = Color(0xFFF5A623);

  static const Color TextColor = Color(0xFF363D59);

  static const Color TabBarColor = Color(0xFF9494AD);


  static const Color borderColor = Color(0xFFF9C63D);

  static const Color hintColor = Color(0xFF363D59);

  // Text Styles
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: TextColor,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: TextColor,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: TextColor,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: TextColor,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: TextColor,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: TextColor,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: TextColor,
  );

  // Button Styles - Updated for PayUni branding
  static final ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: PrimaryColor,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 2,
  );

  // static final ButtonStyle accentButton = ElevatedButton.styleFrom(
  //   backgroundColor: accentColor,
  //   foregroundColor: Colors.white,
  //   padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //   elevation: 2,
  // );
  //
  // static final ButtonStyle secondaryButton = ElevatedButton.styleFrom(
  //   backgroundColor: Colors.white,
  //   foregroundColor: primaryColor,
  //   padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  //   shape: RoundedRectangleBorder(
  //     borderRadius: BorderRadius.circular(12),
  //     side: const BorderSide(color: primaryColor),
  //   ),
  //   elevation: 0,
  // );

  // Input Decoration
  static final InputDecoration inputDecoration = InputDecoration(
    filled: true,
    fillColor: Colors.grey[50],
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey[300]!),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey[300]!),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: PrimaryColor),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );

  // Card Decoration
  static final BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      primaryColor: PrimaryColor,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: PrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButton),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[50],
        border: inputDecoration.border,
        enabledBorder: inputDecoration.enabledBorder,
        focusedBorder: inputDecoration.focusedBorder,
        errorBorder: inputDecoration.errorBorder,
        contentPadding: inputDecoration.contentPadding,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textTheme: const TextTheme(
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
      ),
    );
  }
}
