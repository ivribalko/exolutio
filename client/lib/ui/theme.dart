import 'package:flutter/material.dart';

ThemeData lightTheme(String font) {
  return ThemeData(
    primaryColor: Color.fromRGBO(1, 67, 89, 1),
    accentColor: Color.fromRGBO(1, 67, 89, 1),
    highlightColor: Color.fromRGBO(1, 67, 89, 1),
    brightness: Brightness.light,
    fontFamily: font,
  );
}

ThemeData darkTheme(String font) {
  return ThemeData(
    primaryColor: Colors.black,
    cardColor: Colors.white10,
    scaffoldBackgroundColor: Colors.black,
    canvasColor: Colors.black,
    bottomAppBarColor: Colors.black,
    backgroundColor: Colors.black,
    brightness: Brightness.dark,
    fontFamily: font,
  );
}
