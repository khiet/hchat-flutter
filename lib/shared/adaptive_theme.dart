import 'package:flutter/material.dart';

final ThemeData _iOSTheme = ThemeData(
  primarySwatch: Colors.purple,
  primaryColor: Colors.pink,
  accentColor: Colors.black,
  primaryColorBrightness: Brightness.light,
);

final ThemeData _androidTheme = ThemeData(
  primarySwatch: Colors.purple,
  primaryColor: Colors.pink,
  accentColor: Colors.black,
);

ThemeData getAdaptiveThemeData(BuildContext context) {
  return (Theme.of(context).platform == TargetPlatform.iOS)
      ? _iOSTheme
      : _androidTheme;
}
