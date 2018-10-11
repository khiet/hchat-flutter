import 'package:flutter/material.dart';

class MapPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MapPageState();
  }
}

class MapPageState extends State<MapPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Text('MapPage'),
        ),
      ),
    );
  }
}
