import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../pages/chat_page.dart';
import '../models/user.dart';

class ChatHistory extends StatelessWidget {
  ChatHistory({
    @required this.partnerName,
    @required this.createdAt,
    @required this.previewText,
    @required this.user,
    @required this.roomID,
  });

  final String partnerName;
  final DateTime createdAt;
  final String previewText;
  final User user;
  final String roomID;

  @override
  Widget build(BuildContext context) {
    print('[build (ChatHistory)]');
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.0),
      child: GestureDetector(
        onTap: () => goToChatPage(context),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(right: 15.0),
              child: CircleAvatar(child: Text(partnerName[0])),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  DateFormat.yMMMd().format(createdAt),
                  style: Theme.of(context).textTheme.subhead,
                ),
                Container(
                  margin: EdgeInsets.only(top: 10.0),
                  child: Text(previewText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void goToChatPage(BuildContext context) async {
    QuerySnapshot fbQsRoomUser = await Firestore.instance
        .collection('rooms')
        .document(roomID)
        .collection('users')
        .where('userID', isEqualTo: user.id)
        .getDocuments();

    fbQsRoomUser.documents.forEach((DocumentSnapshot user) {
      user.reference.updateData({'left': false});
    });

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
