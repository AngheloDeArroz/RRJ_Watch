import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final ThemeData rrjAquatiqueTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF3F51B5),
    primary: const Color(0xFF3F51B5),
    secondary: const Color(0xFF40C4FF),
    background: const Color(0xFFF0F2F5),
  ),
  scaffoldBackgroundColor: const Color(0xFFF0F2F5),
  textTheme: GoogleFonts.interTextTheme(),
  cardTheme: const CardThemeData(
    color: Colors.white,
    elevation: 3,
    margin: EdgeInsets.symmetric(vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  ),
);
