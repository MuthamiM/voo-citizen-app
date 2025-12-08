import 'package:flutter/material.dart';

/// App-wide theme colors matching the coral/salmon pink design
class AppTheme {
  // Primary colors
  static const Color primaryPink = Color(0xFFE8847C);
  static const Color lightPink = Color(0xFFF5ADA7);
  static const Color darkPink = Color(0xFFD4635B);
  static const Color bgPink = Color(0xFFF9C5C1);
  
  // Neutral colors
  static const Color textDark = Color(0xFF333333);
  static const Color textMuted = Color(0xFF666666);
  static const Color textLight = Color(0xFF999999);
  static const Color cardBg = Color(0xFFF8F8F8);
  static const Color divider = Color(0xFFE0E0E0);
  
  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryPink, lightPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Input decoration
  static InputDecoration inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
    String? prefix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: textLight),
      prefixIcon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 16),
          Icon(icon, color: primaryPink, size: 22),
          if (prefix != null) ...[
            const SizedBox(width: 10),
            Text(prefix, style: const TextStyle(color: textMuted, fontWeight: FontWeight.w500)),
          ],
          const SizedBox(width: 12),
        ],
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0),
      suffixIcon: suffix,
      filled: true,
      fillColor: cardBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryPink, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }

  // Button styles
  static ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: primaryPink,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );

  static ButtonStyle outlineButton = OutlinedButton.styleFrom(
    foregroundColor: textDark,
    side: const BorderSide(color: divider),
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );

  // Card decoration
  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2))],
  );

  // App ThemeData
  static ThemeData get themeData => ThemeData(
    primaryColor: primaryPink,
    scaffoldBackgroundColor: bgPink,
    colorScheme: ColorScheme.light(
      primary: primaryPink,
      secondary: lightPink,
      surface: Colors.white,
      background: bgPink,
      error: error,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryPink,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButton),
    outlinedButtonTheme: OutlinedButtonThemeData(style: outlineButton),
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) return primaryPink;
        return Colors.transparent;
      }),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    fontFamily: 'Roboto',
  );
}
