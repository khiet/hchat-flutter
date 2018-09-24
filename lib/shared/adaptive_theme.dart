import 'package:flutter/material.dart';

final ThemeData _iOSTheme = ThemeData(
  primarySwatch: Colors.orange,
  primaryColor: Colors.grey[100],
  primaryColorBrightness: Brightness.light,
);

final ThemeData _androidTheme = ThemeData(
  primarySwatch: Colors.purple,
  accentColor: Colors.orangeAccent[400],
);

ThemeData getAdaptiveThemeData(BuildContext context) {
  return (Theme.of(context).platform == TargetPlatform.iOS)
      ? _iOSTheme
      : _androidTheme;
}
