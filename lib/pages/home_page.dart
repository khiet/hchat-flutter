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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                padding: EdgeInsets.symmetric(
                  vertical: 20.0,
                ),
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
          Text('ME: ${user?.debugUsername()}'),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                padding: EdgeInsets.symmetric(
                  vertical: 20.0,
                ),
                child: FlatButton(
                  color: Theme.of(context).accentColor,
                  textColor: Colors.white,
                  child: Text('CLEAR USER ID'),
                  onPressed: _resetUser,
                ),
              ),
            ],
          ),
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

    QuerySnapshot querySnapshot = await Firestore.instance
        .collection('rooms')
        .where('connected', isEqualTo: false)
        .getDocuments();

    DocumentSnapshot availableRoom;
    if (querySnapshot.documents.length > 0) {
      availableRoom = querySnapshot.documents.firstWhere(
          (DocumentSnapshot documentSnapshot) =>
              documentSnapshot['userID'] != user.id,
          orElse: () => null);
    }

    if (availableRoom != null) {
      DocumentSnapshot documentSnapshot = querySnapshot.documents.first;
      roomID = documentSnapshot.documentID;

      await documentSnapshot.reference.updateData({'connected': true});
      await documentSnapshot.reference
          .collection('users')
          .document(user.id)
          .setData({'username': user.username, 'left': false});

      print('[JOINED ROOM] $roomID');
      _hideActivityIndicator();
      goToChatPage(context);
    } else {
      Map<String, dynamic> data = {'connected': false, 'userID': user.id};
      DocumentReference documentReference =
          await Firestore.instance.collection('rooms').add(data);

      await documentReference
          .collection('users')
          .document(user.id)
          .setData({'username': user.username, 'left': false});

      roomID = documentReference.documentID;

      print('[CREATED ROOM] $roomID');

      documentReference.snapshots().listen((DocumentSnapshot snapshot) {
        if (snapshot.exists && snapshot.data['connected']) {
          _hideActivityIndicator();
          goToChatPage(context);
        }
      });
      _showActivityIndicator('Waiting for a user to join...');
    }
  }

  void goToChatPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) => ChatPage(
              roomID: roomID,
              user: user,
            ),
      ),
    );
  }
}
