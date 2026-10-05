import 'package:flutter/material.dart';
import 'app_colours.dart';

class AppTheme {
  static const _fontFamily = 'Inter';

  // Applies Inter to every slot in the base TextTheme without touching colours.
  static TextTheme _interTextTheme([TextTheme? base]) =>
      (base ?? ThemeData.light().textTheme).apply(fontFamily: _fontFamily);

  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: const ColorScheme.light(
          primary: AppColours.lightNavBar,
          onPrimary: AppColours.lightSelectedNav,
          secondary: AppColours.lightSkyBlue,
          onSecondary: AppColours.lightButtonText,
          surface: AppColours.lightCardPanel,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColours.lightNavBar,
          foregroundColor: AppColours.lightSelectedNav,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColours.lightNavBar,
          selectedItemColor: AppColours.lightSelectedNav,
          unselectedItemColor: AppColours.lightUnselectedNav,
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: AppColours.lightNavBar,
          elevation: 0,
          iconColor: AppColours.lightSelectedNav,
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColours.lightSelectedNav,
          ),
          labelTextStyle: const WidgetStatePropertyAll(TextStyle(
            fontFamily: _fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColours.lightSelectedNav,
          )),
        ),
        textTheme: _interTextTheme().copyWith(
          bodyMedium: const TextStyle(fontFamily: _fontFamily, color: AppColours.lightPrimaryText),
          bodySmall: const TextStyle(fontFamily: _fontFamily, color: AppColours.lightSecondaryText),
        ),
      );

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: const ColorScheme.dark(
          primary: AppColours.darkNavBar,
          onPrimary: AppColours.darkSelectedNav,
          secondary: AppColours.darkGoldButton,
          onSecondary: AppColours.gold,
          surface: AppColours.darkCardPanel,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColours.darkNavBar,
          foregroundColor: AppColours.darkSelectedNav,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColours.darkNavBar,
          selectedItemColor: AppColours.darkSelectedNav,
          unselectedItemColor: AppColours.darkUnselectedNav,
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: AppColours.darkNavBar,
          elevation: 0,
          iconColor: AppColours.darkSelectedNav,
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColours.darkSelectedNav,
          ),
          labelTextStyle: const WidgetStatePropertyAll(TextStyle(
            fontFamily: _fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColours.darkSelectedNav,
          )),
        ),
        textTheme: _interTextTheme(ThemeData.dark().textTheme).copyWith(
          bodyMedium: const TextStyle(fontFamily: _fontFamily, color: AppColours.darkPrimaryText),
          bodySmall: const TextStyle(fontFamily: _fontFamily, color: AppColours.darkSecondaryText),
        ),
      );
}
