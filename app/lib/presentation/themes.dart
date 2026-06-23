import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// default intentions:
// "The most authentic thing about us is our capacity to create, to overcome, to endure, to transform, to love, and to be greater than our suffering." – Ben Okri
// "Fairy tales do not tell children that dragons exist. Children already know that dragons exist. Fairy tales tell children that dragons can be killed." - G.K. Chesterton
// "The only way to do great work is to love what you do." – Steve Jobs
// "The best way to find yourself is to lose yourself in the service of others." – Mahatma Gandhi
// "The only limit to our realization of tomorrow will be our doubts of today." – Franklin D. Roosevelt
// "The best way to predict the future is to create it." – Peter Drucker


const lightOnSurfaceColor = Color.fromRGBO(5, 41, 74, 1.0); // Original dark blue
// const lightOnSurfaceColor = Color.fromRGBO(10, 49, 96, 1); // Original dark blue
// final primaryColor = Color.fromRGBO(41, 136, 177, 1); // BEST BLUE
// final primaryColor = Color.fromRGBO(0, 128, 194, 1);
// final primaryColor = Color.fromRGBO(0, 124, 189, 1);
final primaryColor = Color.fromRGBO(5, 128, 249, 1.0);
// final primaryColor = Color.fromRGBO(69, 115, 232, 1.0);
// final primaryColor = Colors.blue.shade700;

final lightTheme3 = ThemeData(
  extensions: <ThemeExtension<dynamic>>[
    PPCustomTheme(),
  ],
// floatingActionButtonTheme: FloatingActionButtonThemeData(),
//   scaffoldBackgroundColor: Colors.white,
  scaffoldBackgroundColor: Color.fromRGBO(233, 238, 249, 1),
  // scaffoldBackgroundColor: Color.fromRGBO(245, 247, 253, 1), // very light blue
  // scaffoldBackgroundColor: const Color.fromRGBO(242, 242, 242, 1), // light grey
//   scaffoldBackgroundColor: const Color.fromRGBO(238, 235, 231, 1), // light beige
//   scaffoldBackgroundColor: const Color.fromRGBO(240, 236, 233, 1), // light beige
  textTheme: TextTheme(
    bodyLarge: TextStyle(color: lightOnSurfaceColor),
    bodyMedium: TextStyle(color: lightOnSurfaceColor),
    bodySmall: TextStyle(color: lightOnSurfaceColor),
  ),
  appBarTheme: AppBarTheme(
    systemOverlayStyle: SystemUiOverlayStyle(statusBarBrightness: Brightness.light),
    backgroundColor: Colors.transparent,
    titleTextStyle: TextStyle(color: lightOnSurfaceColor, fontSize: 20),
    elevation: 0,
    scrolledUnderElevation: 0,
  ),
  colorScheme: ColorScheme.light(
    // error: Colors.redAccent,
    // primary: Color.fromRGBO(120, 181, 170, 1.0),
    // primary: Color.fromRGBO(103,141,198, 1.0),
    // primary: Color.fromRGBO(109,129,150, 1.0),
    // primary: Color.fromRGBO(5, 128, 249, 1.0),
    // primary: Colors.lightGreen,
    // primary: Color.fromRGBO(41, 136, 177, 1), // BEST BLUE
    // primary: Color.fromRGBO(0, 124, 189, 1),
    primary: Color.fromRGBO(5, 128, 249, 1),
    // primary: Color.fromRGBO(69, 115, 232, 1,),
    // BLUE
    // primary: Color.fromRGBO(77, 138, 162, 1.0), // BLUE2
    // primary: Color.fromRGBO(144, 178, 119, 1), // GREEN
    // primary: Color.fromRGBO(106, 137, 167, 1.0),
    // primary: Color.fromRGBO(241,122,94, 1.0),
    // primary: Color.fromRGBO(170, 190, 239, 1.0),
    // primary: Colors.blueGrey,
    // secondary: Colors.lime,
    // secondary: Color.fromRGBO(41, 136, 177, 1), // BLUE
    // secondary: Color.fromRGBO(144, 178, 119, 1),
    secondary: Colors.green.shade400,
    // GREEN
    background: Colors.white,
// onBackground: Colors.orange,
    inversePrimary: Colors.green,
    primaryContainer: Colors.white,
    tertiary: Colors.blueGrey,
    // surface: Colors.white,
    // surface: Color.fromRGBO(252, 248, 243, 1.0), // very light beige
    surface: Color.fromRGBO(245, 247, 253, 1.0),
    surfaceDim: Color.fromRGBO(35, 38, 59, 1.0),
    // very light blue
    surfaceTint: Color.fromRGBO(225, 231, 243, 1),
    surfaceBright: Color.fromRGBO(237, 241, 248, 1),
    onSurface: lightOnSurfaceColor,
  ),
  checkboxTheme: CheckboxThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
  ),
  floatingActionButtonTheme:
      const FloatingActionButtonThemeData(backgroundColor: Color.fromRGBO(255, 106, 106, 1)),
  cupertinoOverrideTheme: CupertinoThemeData(
    // primaryColor: Color.fromRGBO(41, 136, 177, 1), // BLUE
    primaryColor: primaryColor, // BLUE
    // primaryColor: Color.fromRGBO(77, 138, 162, 1), // BLUE2
  ),
  bottomSheetTheme: BottomSheetThemeData(
      modalBackgroundColor: Color.fromRGBO(233, 238, 249, 1), // Set the background color
      dragHandleColor: lightOnSurfaceColor.withValues(alpha:.4)),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateColor.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return Color.fromRGBO(245, 247, 253, 1);
      }
      return lightOnSurfaceColor;
    }),
    trackOutlineColor: WidgetStateColor.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return Color.fromRGBO(245, 247, 253, 1.0);
      }
      return lightOnSurfaceColor;
    }),
    // trackColor: WidgetStateProperty.all<Color>(Color.fromRGBO(0, 124, 189, 1).withValues(alpha:.5)),
  ),
);

final darkTheme4 = ThemeData(
  extensions: <ThemeExtension<dynamic>>[
    PPCustomTheme(
      infoColor: Colors.lightGreen,
      unprayedColor: Colors.pink.shade200,
    ),
  ],
  scaffoldBackgroundColor: Color.fromRGBO(29, 33, 36, 1),
  // Darker background
// scaffoldBackgroundColor: Colors.blueGrey,
  appBarTheme: const AppBarTheme(
    systemOverlayStyle: SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
    backgroundColor: Colors.transparent,
// titleTextStyle: TextStyle(color: Colors.black),
    elevation: 0,
  ),
  checkboxTheme: CheckboxThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
  ),
  colorScheme: ColorScheme.dark(
    background: Color.fromRGBO(50, 50, 50, 1),
    // error: Colors.blueGrey,
    // primary: Color.fromRGBO(106, 137, 167, 1.0),
    // primary: Color.fromRGBO(144, 178, 119, 1), // GREEN
    // primary: Color.fromRGBO(77, 138, 162, 1), // BLUE2
    // primary: Color.fromRGBO(41, 136, 177, 1), // BEST BLUE
    primary: primaryColor,
    // BLUE
    // secondary: Color.fromRGBO(144, 178, 119, 1),
    // secondary: Colors.lightGreen,
    secondary: Colors.green.shade300,
    // GREEN
    surface: Color.fromRGBO(45, 49, 58, 1),
    surfaceDim: Color.fromRGBO(215, 224, 238, 1),
    // Darker variant of the light theme's surface
    // surface: Color.fromRGBO(28, 32, 36, 1), // Darker variant of the light theme's surface
    surfaceTint: Color.fromRGBO(22, 25, 27, 1),
    surfaceBright: Color.fromRGBO(17, 19, 21, 1),
    // Slightly lighter than surface for depth
    // surfaceTint: Color.fromRGBO(28, 32, 36, 1), // Slightly darker than scaffoldBackgroundColor
    onSurface: Color.fromRGBO(215, 224, 238, 1), // Light text for readability on dark surfaces
    // onSurfaceVariant: Color.fromRGBO(200, 208, 220, 1), // Light text for readability on dark surfaces
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color.fromRGBO(70, 70, 70, 1),
      foregroundColor: Color.fromRGBO(255, 106, 106, 1)),
  bottomSheetTheme: BottomSheetThemeData(
      modalBackgroundColor: Color.fromRGBO(29, 33, 36, 1), // Set the background color
      dragHandleColor: Color.fromRGBO(200, 208, 220, 1).withValues(alpha:.4),
      modalBarrierColor: Color.fromRGBO(0, 0, 0, 1).withValues(alpha:.75)),
  dialogTheme: DialogThemeData(
    backgroundColor: Color.fromRGBO(29, 33, 36, 1),
    // backgroundColor: Color.fromRGBO(33, 37, 41, 1),
    // backgroundColor: Color.fromRGBO(28, 32, 36, 1),
    barrierColor: Color.fromRGBO(0, 0, 0, 1).withValues(alpha:.75),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateColor.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return Color.fromRGBO(29, 33, 36, 1);
      }
      return Color.fromRGBO(215, 224, 238, 1);
    }),
    trackOutlineColor: WidgetStateColor.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return Color.fromRGBO(45, 49, 58, 1);
      }
      return Color.fromRGBO(215, 224, 238, 1);
    }),
    // trackColor: WidgetStateProperty.all<Color>(Color.fromRGBO(0, 124, 189, 1).withValues(alpha:.5)),
  ),
);

class PPCustomTheme extends ThemeExtension<PPCustomTheme> {
  late EdgeInsets customPadding;
  late Color infoColor;
  late Color prayerListColor;
  late Color unprayedColor;

  PPCustomTheme({
    EdgeInsets? customPadding,
    Color? infoColor,
    Color? prayerListColor,
    Color? unprayedColor,
  }) {
    this.customPadding = customPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    this.infoColor = infoColor ?? Colors.lightGreen.shade700;
    this.prayerListColor = prayerListColor ?? Colors.lightBlue;
    // this.unprayedColor = unprayedColor ?? Colors.pinkAccent.shade100;
    this.unprayedColor = unprayedColor ?? Colors.pink.shade400;
    // this.unprayedColor = unprayedColor ?? Colors.pink.shade900;
  }

  @override
  PPCustomTheme copyWith({
    EdgeInsets? customPadding,
    Color? infoColor,
    Color? prayerListColor,
    Color? unprayedColor,
  }) {
    return PPCustomTheme(
      customPadding: customPadding ?? this.customPadding,
      infoColor: infoColor ?? this.infoColor,
      prayerListColor: prayerListColor ?? this.prayerListColor,
      unprayedColor: unprayedColor ?? this.unprayedColor,
    );
  }

  @override
  PPCustomTheme lerp(ThemeExtension<PPCustomTheme>? other, double t) {
    if (other is! PPCustomTheme) return this;
    return PPCustomTheme(
      customPadding: EdgeInsets.fromLTRB(
        customPadding.left + (other.customPadding.left - customPadding.left) * t,
        customPadding.top + (other.customPadding.top - customPadding.top) * t,
        customPadding.right + (other.customPadding.right - customPadding.right) * t,
        customPadding.bottom + (other.customPadding.bottom - customPadding.bottom) * t,
      ),
      infoColor: Color.lerp(infoColor, other.infoColor, t)!,
      prayerListColor: Color.lerp(prayerListColor, other.prayerListColor, t)!,
      unprayedColor: Color.lerp(unprayedColor, other.unprayedColor, t)!,
    );
  }
}
