import 'package:flutter/material.dart';

import 'package:firebase_messaging/firebase_messaging.dart';

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
  Widget _messageNotification = Container();

  @override
  void initState() {
    super.initState();

    _setupFCM();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("HChat"),
        elevation: Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
      ),
      body: Stack(
        children: <Widget>[_messageNotification, _pages[_tabIndex]],
      ),
      bottomNavigationBar: BottomNavigationBar(
        onTap: _onTapHandler,
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

  Widget _buildMessageNotification(BuildContext context, String message) {
    return Container(
      margin: EdgeInsets.all(10.0),
      padding: EdgeInsets.all(10.0),
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: Theme.of(context).accentColor,
        borderRadius: BorderRadius.all(
          Radius.circular(
            2.0,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            child: Icon(
              Icons.notifications_active,
              color: Colors.white,
            ),
            margin: EdgeInsets.only(right: 5.0),
          ),
          Text(
            message,
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _onTapHandler(int tabIndex) {
    setState(() {
      _tabIndex = tabIndex;
    });
  }

  void _setupFCM() async {
    final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
    String token = await _firebaseMessaging.getToken();
    print('[_setupFCM] $token');

    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print('[_setupFCM] onMessage $message');
        setState(() {
          _messageNotification = _buildMessageNotification(
              context, message['notification']['title']);
        });
      },
      onResume: (Map<String, dynamic> message) async {
        print('[_setupFCM] onResume $message');
      },
      onLaunch: (Map<String, dynamic> message) async {
        print('[_setupFCM] onLaunch $message');
      },
    );
  }
}
