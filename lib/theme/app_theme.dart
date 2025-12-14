import 'package:flutter/material.dart';

class AppTheme {
  // Color Palette
  static const Color slate50 = Color(0xFFf8fafc);
  static const Color slate200 = Color(0xFFe2e8f0);
  static const Color slate500 = Color(0xFF64748b);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate900 = Color(0xFF0f172a);

  static const Color blue50 = Color(0xFFeff6ff);
  static const Color blue100 = Color(0xFFdbeafe);
  static const Color blue600 = Color(0xFF2563eb);

  static const Color indigo50 = Color(0xFFeef2ff);
  static const Color indigo100 = Color(0xFFe0e7ff);
  static const Color indigo600 = Color(0xFF4f46e5);

  static const Color emerald50 = Color(0xFFecfdf5);
  static const Color emerald100 = Color(0xFFd1fae5);
  static const Color emerald500 = Color(0xFF10b981);
  static const Color emerald600 = Color(0xFF059669);
  static const Color emerald700 = Color(0xFF047857);

  static const Color red500 = Color(0xFFef4444);
  static const Color red600 = Color(0xFFdc2626);

  static const Color yellow600 = Color(0xFFd97706);
  static const Color orange50 = Color(0xFFfff7ed);

  // Gradients
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      slate50,
      Color(0x4deff6ff), // blue-50 with 30% opacity
      Color(0x33eef2ff), // indigo-50 with 20% opacity
    ],
  );

  static const LinearGradient emergencyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [red500, red600],
  );

  // Glass Morphism Effect
  static BoxDecoration glassMorphismDecoration({
    double opacity = 0.7,
    double blurRadius = 4.0,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: Colors.white.withOpacity(opacity),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: borderColor ?? slate200.withOpacity(0.5),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: blurRadius,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  // Status Indicator Decoration
  static BoxDecoration statusIndicatorDecoration(Color color) {
    return BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.3),
          blurRadius: 8,
          spreadRadius: 2,
        ),
      ],
    );
  }

  // Card Decoration
  static BoxDecoration cardDecoration = glassMorphismDecoration();

  // Button Styles
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: blue600,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 2,
    textStyle: const TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 16,
    ),
  );

  static ButtonStyle sosButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.transparent,
    foregroundColor: Colors.white,
    padding: EdgeInsets.zero,
    shape: const CircleBorder(),
    elevation: 8,
    shadowColor: red600.withOpacity(0.3),
    fixedSize: const Size(96, 96),
  );

  static ButtonStyle outlineButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: slate600,
    side: BorderSide(color: slate200.withOpacity(0.5), width: 1),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    textStyle: const TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 16,
    ),
  );

  // Text Styles
  static const TextStyle headingLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: slate900,
    letterSpacing: -0.5,
    height: 1.25,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: slate900,
    letterSpacing: -0.25,
    height: 1.25,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: slate900,
    letterSpacing: -0.25,
    height: 1.25,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: slate900,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: slate600,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: slate500,
    height: 1.5,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: slate900,
    height: 1.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: slate600,
    height: 1.5,
  );

  // Input Decoration
  static InputDecoration inputDecoration({
    required String hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: bodyMedium,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: slate50.withOpacity(0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: slate200.withOpacity(0.5),
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: slate200.withOpacity(0.5),
          width: 1,
        ),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(
          color: blue600,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    );
  }

  // Theme Data
  static ThemeData lightTheme = ThemeData(
    primaryColor: blue600,
    colorScheme: ColorScheme.fromSeed(
      seedColor: blue600,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: slate900),
      titleTextStyle: headingMedium,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: primaryButtonStyle,
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: outlineButtonStyle,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: slate50.withOpacity(0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: slate200.withOpacity(0.5),
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: slate200.withOpacity(0.5),
          width: 1,
        ),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(
          color: blue600,
          width: 2,
        ),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: headingLarge,
      headlineMedium: headingMedium,
      headlineSmall: headingSmall,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: bodySmall,
      labelMedium: labelMedium,
      labelSmall: labelSmall,
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    useMaterial3: true,
  );
}
