import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './chat_page.dart';

import '../shared/adaptive_activity_indicator.dart';

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return HomePageState();
  }
}

class HomePageState extends State<HomePage> {
  Widget activityIndicator;
  String userID;
  String roomID;

  @override
  void initState() {
    super.initState();

    _initUserID();
  }

  void _initUserID() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String prefUserID = prefs.get('userID');
    if (prefUserID == null) {
      prefUserID = Uuid().v4();
      await prefs.setString('userID', prefUserID);
    }

    setState(() {
      userID = prefUserID;
    });
  }

  void _clearUserID() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userID');

    _initUserID();
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
                        color: Theme.of(context).accentColor,
                        textColor: Theme.of(context).primaryColor,
                        child: Text('FIND USER'),
                        onPressed: _findUser,
                      ),
              ),
            ],
          ),
          Text('ME: $userID'),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                padding: EdgeInsets.symmetric(
                  vertical: 20.0,
                ),
                child: FlatButton(
                  color: Theme.of(context).primaryColor,
                  textColor: Theme.of(context).accentColor,
                  child: Text('CLEAR USER ID'),
                  onPressed: _clearUserID,
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
      availableRoom = querySnapshot.documents
          .firstWhere((DocumentSnapshot documentSnapshot) {
        return documentSnapshot.data['userID'] != userID;
      });
    }

    if (availableRoom != null) {
      DocumentSnapshot documentSnapshot = querySnapshot.documents.first;
      roomID = documentSnapshot.documentID;

      updateUserRooms(roomID);
      await documentSnapshot.reference.updateData({'connected': true});
      await documentSnapshot.reference
          .collection('users')
          .document(userID)
          .setData({'username': userID, 'left': false});

      print('[JOINED ROOM] $roomID');
      _hideActivityIndicator();
      goToChatPage();
    } else {
      Map<String, dynamic> data = {'connected': false, 'userID': userID};
      DocumentReference documentReference =
          await Firestore.instance.collection('rooms').add(data);

      await documentReference
          .collection('users')
          .document(userID)
          .setData({'username': userID, 'left': false});

      roomID = documentReference.documentID;

      updateUserRooms(roomID);
      print('[CREATED ROOM] $roomID');

      documentReference.snapshots().listen((DocumentSnapshot snapshot) {
        if (snapshot.exists && snapshot.data['connected']) {
          _hideActivityIndicator();
          goToChatPage();
        }
      });
      _showActivityIndicator('Waiting for a user to join...');
    }
  }

  void goToChatPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) => ChatPage(
              roomID: roomID,
              userID: userID,
            ),
      ),
    );
  }

  void updateUserRooms(String roomID) async {
    List<dynamic> rooms = [roomID];
    DocumentSnapshot ds =
        await Firestore.instance.collection('users').document(userID).get();

    if (ds.exists) {
      rooms.addAll(ds['rooms']);
    }

    await Firestore.instance
        .collection('users')
        .document(userID)
        .setData({'rooms': rooms});
  }
}
