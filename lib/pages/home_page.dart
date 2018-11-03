import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import './chat_page.dart';
import '../models/user.dart';
import '../shared/adaptive_activity_indicator.dart';

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return HomePageState();
  }
}

class HomePageState extends State<HomePage> {
  Widget activityIndicator;
  User user;
  String roomID;

  @override
  void initState() {
    super.initState();

    _initUser();
  }

  void _initUser() async {
    user = await User.findOrCreate();

    setState(() {
      user = user;
    });
  }

  void _resetUser() async {
    _hideActivityIndicator();
    await User.destroy();

    _initUser();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'Your name is ${user?.username}',
            style: Theme.of(context).textTheme.title,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(top: 20.0),
                child: activityIndicator != null
                    ? activityIndicator
                    : FlatButton(
                        color: Theme.of(context).primaryColor,
                        textColor: Colors.white,
                        child: Text('FIND USER'),
                        onPressed: _findUser,
                      ),
              ),
            ],
          ),
          _buildResetUser(),
        ],
      ),
    );
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

  void _hideActivityIndicator() {
    setState(() {
      activityIndicator = null;
    });
  }

  void _findUser() async {
    _showActivityIndicator('Looking for a user...');

    final QuerySnapshot fbQsRooms = await Firestore.instance
        .collection('rooms')
        .where('connected', isEqualTo: false)
        .where('dead', isEqualTo: false)
        .getDocuments();

    DocumentSnapshot availableRoom;
    if (fbQsRooms.documents.length > 0) {
      availableRoom = fbQsRooms.documents.firstWhere(
          (DocumentSnapshot documentSnapshot) =>
              documentSnapshot['userID'] != user.id,
          orElse: () => null);
    }

    if (availableRoom != null) {
      DocumentSnapshot fbRoom = fbQsRooms.documents.first;
      roomID = fbRoom.documentID;

      await fbRoom.reference.updateData({'connected': true});
      await fbRoom.reference
          .collection('users')
          .add({'username': user.username, 'left': false, 'userID': user.id});

      print('[JOINED ROOM] $roomID');
      _hideActivityIndicator();
      _goToChatPage(context);
    } else {
      _createRoomAndWaitForUser();

      _showActivityIndicator('Waiting for a user to join...');
    }
  }

  void _createRoomAndWaitForUser() async {
    final Duration findUserDuration = Duration(seconds: 30);

    final Map<String, dynamic> data = {
      'connected': false,
      'userID': user.id,
      'dead': false
    };
    final DocumentReference fbRoom =
        await Firestore.instance.collection('rooms').add(data);
    await fbRoom
        .collection('users')
        .add({'username': user.username, 'left': false, 'userID': user.id});
    roomID = fbRoom.documentID;
    print('[CREATED ROOM] $roomID');

    final Timer findUserTimer =
        Timer(findUserDuration, () => _cancelByUserNotFound(fbRoom));

    fbRoom.snapshots().listen((DocumentSnapshot snapshot) {
      if (snapshot.exists && snapshot.data['connected']) {
        findUserTimer.cancel();
        _hideActivityIndicator();
        _goToChatPage(context);
      }
    });
  }

  void _cancelByUserNotFound(DocumentReference fbRoom) {
    print('[warnUserNotFound]');

    fbRoom.updateData({'dead': true});

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('User could not be found.'),
          content: Text("Please try again later."),
          actions: <Widget>[
            FlatButton(
              child: Text("OK"),
              onPressed: () {
                _hideActivityIndicator();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _goToChatPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) => ChatPage(
              roomID: roomID,
              user: user,
            ),
      ),
    );
  }

  Widget _buildResetUser() {
    return (user != null)
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Column(
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.only(top: 20.0),
                    child: FlatButton(
                      color: Theme.of(context).accentColor,
                      textColor: Colors.white,
                      child: Text('CLEAR USER ID'),
                      onPressed: _resetUser,
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 20.0),
                    child: Text(user?.id),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 20.0),
                    child: Text(user?.username),
                  ),
                ],
              ),
            ],
          )
        : Container();
  }
}
