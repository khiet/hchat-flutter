import 'package:flutter/material.dart';
import './home_page.dart';
import './map_page.dart';
import './history_page.dart';

class MainPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MainPageState();
  }
}

class MainPageState extends State<MainPage> {
  int _tabIndex = 0;
  final List<Widget> _pages = [
    HomePage(),
    HistoryPage(),
    MapPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("HChat"),
        elevation: Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
      ),
      body: _pages[_tabIndex],
      bottomNavigationBar: BottomNavigationBar(
        onTap: onTapHandler,
        currentIndex: _tabIndex,
        items: [
          BottomNavigationBarItem(
            icon: new Icon(Icons.home),
            title: new Text('Home'),
          ),
          BottomNavigationBarItem(
            icon: new Icon(Icons.history),
            title: new Text('Histories'),
          ),
          BottomNavigationBarItem(
            icon: new Icon(Icons.map),
            title: new Text('Map'),
          ),
        ],
      ),
    );
  }

  void onTapHandler(int tabIndex) {
    setState(() {
      _tabIndex = tabIndex;
    });
  }
}
