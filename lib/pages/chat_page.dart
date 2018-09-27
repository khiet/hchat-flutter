import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/chat_message.dart';
import '../widgets/main_input.dart';

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
  MainInput _mainInput;
  Image _previewImage;

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
      Firestore.instance.collection('chats').document().setData({'chat': text});
    });
  }

  void imageHandler(File image) {
    Image previewImage = Image.file(
      image,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      height: 200.0,
      width: MediaQuery.of(context).size.width,
    );

    setState(() {
      _previewImage = previewImage;
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

    _mainInput = MainInput(
        chatInputHandler: chatInputHandler, imageHandler: imageHandler);
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
            _previewImage != null ? _previewImage : Container(),
            Divider(height: 1.0),
            Container(
              decoration: BoxDecoration(color: Theme.of(context).cardColor),
              child: _mainInput,
            ),
          ],
        ),
      ),
    );
  }
}
