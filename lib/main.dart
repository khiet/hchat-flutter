import 'package:flutter/material.dart';

import 'pages/main_page.dart';
import 'shared/adaptive_theme.dart';

void main() {
  runApp(FriendlychatApp());
}

class FriendlychatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "HChat",
      theme: getAdaptiveThemeData(context),
      routes: {
        '/': (BuildContext context) => MainPage(),
      },
    );
  }
}
