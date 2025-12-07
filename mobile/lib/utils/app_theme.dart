import 'package:flutter/material.dart';

/// App-wide theme colors matching the Dark Orange design
/// Background: #1A1A1A
/// Primary Accent: #FF8C00
class AppTheme {
  // Primary colors
  static const Color primaryOrange = Color(0xFFFF8C00);
  static const Color darkOrange = Color(0xFFE67E00);
  static const Color lightOrange = Color(0xFFFFB347);
  static const Color bgDark = Color(0xFF1A1A1A);
  
  // Surface colors
  static const Color cardDark = Color(0xFF2A2A2A);
  static const Color inputBg = Color(0xFF1A1A1A); // Dark black input
  static const Color divider = Color(0xFF444444);
  
  // Text colors
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF888888);
  static const Color textDark = Color(0xFF1A1A1A); // for buttons
  
  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFCF6679);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryOrange, lightOrange],
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
      hintStyle: const TextStyle(color: textMuted),
      prefixIcon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 16),
          Icon(icon, color: primaryOrange, size: 22),
          if (prefix != null) ...[
            const SizedBox(width: 10),
            Text(prefix, style: const TextStyle(color: textLight, fontWeight: FontWeight.w500)),
          ],
          const SizedBox(width: 12),
        ],
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0),
      suffixIcon: suffix,
      filled: true,
      fillColor: inputBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryOrange, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }

  // Button styles
  static ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: primaryOrange,
    foregroundColor: bgDark,
    elevation: 0,
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
  );

  static ButtonStyle outlineButton = OutlinedButton.styleFrom(
    foregroundColor: textLight,
    side: const BorderSide(color: divider),
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );

  // Card decoration
  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardDark,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: divider.withOpacity(0.5)),
    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
  );

  // App ThemeData
  static ThemeData get themeData => ThemeData(
    primaryColor: primaryOrange,
    scaffoldBackgroundColor: const Color(0xFF000000),
    colorScheme: const ColorScheme.dark(
      primary: primaryOrange,
      secondary: lightOrange,
      surface: cardDark,
      background: bgDark,
      error: error,
      onPrimary: bgDark,
      onSecondary: bgDark,
      onSurface: textLight,
      onBackground: textLight,
      onError: bgDark,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bgDark,
      foregroundColor: textLight,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textLight),
      iconTheme: IconThemeData(color: textLight),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButton),
    outlinedButtonTheme: OutlinedButtonThemeData(style: outlineButton),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: bgDark, // Dark black input background
      hintStyle: const TextStyle(color: textMuted),
      labelStyle: const TextStyle(color: textLight),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14), 
        borderSide: const BorderSide(color: divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14), 
        borderSide: const BorderSide(color: divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14), 
        borderSide: const BorderSide(color: primaryOrange, width: 1.5),
      ),
    ),
    cardTheme: CardTheme(
      color: cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) return primaryOrange;
        return Colors.transparent;
      }),
      checkColor: MaterialStateProperty.all(bgDark),
      side: const BorderSide(color: textMuted, width: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: cardDark,
      selectedItemColor: primaryOrange,
      unselectedItemColor: textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 10,
    ),
    fontFamily: 'Roboto',
    useMaterial3: true,
    // Input cursor and text selection colors
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Color(0xFFFFCC00), // Yellow cursor
      selectionColor: Color(0x40FF8C00),
      selectionHandleColor: primaryOrange,
    ),
  );
}
