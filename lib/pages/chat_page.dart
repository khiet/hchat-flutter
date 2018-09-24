import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/chat_message.dart';
import '../widgets/chat_input.dart';

class ChatPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return ChatPageState();
  }
}

class ChatPageState extends State<ChatPage> {
  ChatInput _chatInput;
  Widget _chatMessageList;
  String _username = (['マンモス', 'カエル']..shuffle()).first;

  void chatInputHandler(String text) {
    Firestore.instance.runTransaction((transaction) async {
      Firestore.instance.collection('chats').add({'chat': text});
    });
  }

  @override
  void initState() {
    _chatInput = ChatInput(onSubmitted: chatInputHandler);
    _chatMessageList = Flexible(
      child: StreamBuilder(
        stream: Firestore.instance.collection('chats').snapshots(),
        builder: (_, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              padding: EdgeInsets.all(8.0),
              reverse: true,
              itemBuilder: (_, int index) {
                return ChatMessage(
                  text: snapshot.data.documents[index]['chat'],
                  username: _username,
                );
              },
              itemCount: snapshot.data.documents.length,
            );
          } else {
            return Container();
          }
        },
      ),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print('build inside ChatPage');
    return Scaffold(
      appBar: AppBar(
        title: Text("Friendlychat"),
        elevation: Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
      ),
      body: Container(
        decoration: Theme.of(context).platform == TargetPlatform.iOS
            ? BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[200]),
                ),
              )
            : null,
        child: Column(
          children: <Widget>[
            _chatMessageList,
            Divider(height: 1.0),
            Container(
              decoration: BoxDecoration(color: Theme.of(context).cardColor),
              child: _chatInput,
            ),
          ],
        ),
      ),
    );
  }
}
