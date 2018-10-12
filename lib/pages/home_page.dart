import 'package:flutter/material.dart';

import '../shared/adaptive_activity_indicator.dart';

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return HomePageState();
  }
}

class HomePageState extends State<HomePage> {
  Widget activityIndicator;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: activityIndicator != null
              ? activityIndicator
              : FlatButton(
                  color: Theme.of(context).accentColor,
                  textColor: Theme.of(context).primaryColor,
                  child: Text('FIND USER'),
                  onPressed: _findUser,
                ),
        ),
      ),
    );
  }

  void _findUser() {
    print('[findUser]');

    setState(() {
      activityIndicator = Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AdaptiveActivityIndicator(),
          Container(
            padding: EdgeInsets.only(top: 20.0),
            child: Text('Looking for a user..'),
          ),
        ],
      );
    });
  }
}
