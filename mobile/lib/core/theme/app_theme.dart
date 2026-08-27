import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary   = Color(0xFF1A56DB);
  static const Color secondary = Color(0xFF0E9F6E);
  static const Color error     = Color(0xFFE02424);
  static const Color bg        = Color(0xFFF9FAFB);

  static ThemeData get light => ThemeData(
    colorSchemeSeed: primary,
    scaffoldBackgroundColor: bg,
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF111827),
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );
}
