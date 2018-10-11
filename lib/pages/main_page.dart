import 'package:flutter/material.dart';
import './chat_page.dart';
import './map_page.dart';

class MainPage extends StatelessWidget {
  final PageController controller = PageController(initialPage: 0);

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: controller,
      children: <Widget>[
        MapPage(),
        ChatPage(),
      ],
    );
  }
}
