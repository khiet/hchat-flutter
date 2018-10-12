import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../shared/adaptive_activity_indicator.dart';

class HomePage extends StatefulWidget {
  final PageController pageController;

  HomePage({this.pageController});

  @override
  State<StatefulWidget> createState() {
    return HomePageState();
  }
}

class HomePageState extends State<HomePage> {
  StreamSubscription<QuerySnapshot> _subscription;
  Widget activityIndicator;
  String user_id;

  void roomStreamHandler(QuerySnapshot snapshot) {
    print('[roomStreamHandler] $snapshot');
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    user_id = Uuid().v4();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("HChat"),
        elevation: Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
      ),
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

  void _createRoom() {
    Map<String, dynamic> data = {
      'active': false,
      'connected': false,
      'user_id': user_id,
      'created_at': DateTime.now()
    };

    Firestore.instance.runTransaction((transaction) async {
      Firestore.instance.collection('rooms').document().setData(data);
    });
  }

  void _showActivityIndicator(String text) {
    setState(() {
      activityIndicator = Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AdaptiveActivityIndicator(),
          Container(
            padding: EdgeInsets.only(top: 20.0),
            child: Text(text),
          ),
        ],
      );
    });
  }

  void _findUser() {
    _showActivityIndicator('Looking for a user...');

    _subscription = Firestore.instance
        .collection('rooms')
        .where('active', isEqualTo: false)
        .where('connected', isEqualTo: false)
        .snapshots()
        .listen(_roomAssignmentHandler);
  }

  void _roomAssignmentHandler(QuerySnapshot openRoom) {
    if (openRoom.documents.isEmpty) {
      print('[_createRoom]');
      _createRoom();
    } else {
      openRoom.documents.forEach((room) {
        if (room['user_id'] != user_id) {
          print('[JOIN]');
          widget.pageController.animateToPage(
            1,
            duration: Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        } else {
          _showActivityIndicator('Waiting for a user to join...');
        }
      });
    }
  }
}
