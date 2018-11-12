import 'package:flutter/material.dart';

class ChatImagePage extends StatelessWidget {
  final Image imageWidget;

  ChatImagePage({@required this.imageWidget});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          "HChat",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0.0,
        backgroundColor: Colors.black,
      ),
      body: Center(child: imageWidget),
    );
  }
}
