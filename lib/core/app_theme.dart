import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swift_chat/main.dart';

TextTheme buildTextTheme(Color textColor) => TextTheme(
  bodyLarge: GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textColor,
  ),
  bodyMedium: GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textColor,
  ),
  bodySmall: GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textColor,
  ),
  titleLarge: GoogleFonts.robotoSlab(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: textColor,
  ),
  titleMedium: GoogleFonts.robotoSlab(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: textColor,
  ),
  labelSmall: GoogleFonts.montserrat(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textColor,
  ),
  labelMedium: GoogleFonts.montserrat(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textColor,
  ),
  labelLarge: GoogleFonts.montserrat(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textColor,
  ),
);

AppBarTheme buildAppBarTheme({required bool isDark}) => AppBarTheme(
  foregroundColor: Colors.white,
  backgroundColor: primaryColor.shade500,
  elevation: 0,
  iconTheme: IconThemeData(color: Colors.white),
  titleTextStyle: GoogleFonts.robotoSlab(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  ),
  centerTitle: true,
  toolbarHeight: 46,
  titleSpacing: 0,
);

BottomNavigationBarThemeData buildBottomNavBarTheme({required bool isDark}) =>
    BottomNavigationBarThemeData(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      selectedItemColor: primaryColor,
      unselectedItemColor: isDark ? Colors.white54 : Colors.black54,
      selectedLabelStyle: GoogleFonts.montserrat(
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      unselectedLabelStyle: GoogleFonts.montserrat(
        fontWeight: FontWeight.w400,
        fontSize: 12,
      ),
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
      elevation: 10,
      landscapeLayout: BottomNavigationBarLandscapeLayout.centered,
    );

ElevatedButtonThemeData buildElevatedButtonTheme({required bool isDark}) =>
    ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: isDark ? Colors.black87 : Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.montserrat(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );

TextButtonThemeData buildTextButtonTheme({
  required bool isDark,
}) => TextButtonThemeData(
  style: TextButton.styleFrom(
    foregroundColor:
        isDark
            ? primaryColor
            : primaryColor, // replace shade200 if primaryColor is not MaterialColor
    textStyle: GoogleFonts.montserrat(
      fontWeight: FontWeight.w600,
      fontSize: 14,
    ),
  ),
);
