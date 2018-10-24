import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import './chat_page.dart';

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
  Widget activityIndicator;
  String userID;
  String roomID;

  @override
  void initState() {
    super.initState();

    userID = Uuid().v4();
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
                  child: Text('FIND USER $userID'),
                  onPressed: _findUser,
                ),
        ),
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

      await documentSnapshot.reference.updateData({'connected': true});
      await documentSnapshot.reference
          .collection('users')
          .document(userID)
          .setData({'username': userID, 'left': false});

      print('[JOINED ROOM] $roomID');
      _hideActivityIndicator();
      goToChatPage();
    } else {
      Map<String, dynamic> data = {
        'connected': false,
        'userID': userID,
        'createdAt': DateTime.now()
      };
      DocumentReference documentReference =
          await Firestore.instance.collection('rooms').add(data);

      await documentReference
          .collection('users')
          .document(userID)
          .setData({'username': userID, 'left': false});

      roomID = documentReference.documentID;
      print('[CREATED ROOM] $roomID');

      documentReference.snapshots().listen((DocumentSnapshot snapshot) {
        if (snapshot.data['connected']) {
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
}
