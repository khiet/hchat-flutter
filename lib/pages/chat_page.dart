import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/chat_message.dart';
import '../widgets/chat_input.dart';

import '../globals/usernames.dart';

class ChatPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return ChatPageState();
  }
}

class ChatPageState extends State<ChatPage> {
  final String _username = (usernames..shuffle()).first;

  List<ChatMessage> _messages = [];
  StreamSubscription<QuerySnapshot> _subscription;
  ChatInput _chatInput;

  void chatStreamHandler(QuerySnapshot snapshot) {
    final List<ChatMessage> newMessages = [];
    for (DocumentSnapshot document in snapshot.documents) {
      newMessages.insert(
          0, ChatMessage(text: document['chat'], username: _username));
    }

    setState(() {
      _messages = newMessages;
    });
  }

  void chatInputHandler(String text) {
    Firestore.instance.runTransaction((transaction) async {
      Firestore.instance.collection('chats').add({'chat': text});
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _subscription = Firestore.instance
        .collection('chats')
        .snapshots()
        .listen(chatStreamHandler);

    _chatInput = ChatInput(onSubmitted: chatInputHandler);
  }

  @override
  Widget build(BuildContext context) {
    print('[ChatPage]');
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
            Flexible(
              child: ListView.builder(
                padding: EdgeInsets.all(8.0),
                reverse: true,
                itemBuilder: (_, int index) {
                  return _messages[index];
                },
                itemCount: _messages.length,
              ),
            ),
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
