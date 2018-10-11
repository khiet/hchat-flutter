import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

import '../widgets/chat_message.dart';
import '../widgets/chat_text.dart';
import '../widgets/chat_image.dart';
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

  void chatStreamHandler(QuerySnapshot snapshot) {
    final List<ChatMessage> newMessages = [];
    for (DocumentSnapshot document in snapshot.documents) {
      final Widget message = (document['imageUrl'] != null)
          ? ChatImage(imageUrl: document['imageUrl'])
          : ChatText(text: document['text']);

      newMessages.insert(
        0,
        ChatMessage(
          message: message,
          username: _username,
          sentAt: document['sent_at'],
        ),
      );
    }

    setState(() {
      _messages = newMessages;
    });
  }

  void chatInputHandler(String text) {
    Firestore.instance.runTransaction((transaction) async {
      Firestore.instance
          .collection('chats')
          .document()
          .setData({'text': text, 'sent_at': DateTime.now()});
    });
  }

  void imageHandler(File image) async {
    final Map<String, dynamic> uploadedData = await uploadImage(image);
    Firestore.instance.runTransaction((transaction) async {
      Firestore.instance.collection('chats').document().setData(
          {'imageUrl': uploadedData['imageUrl'], 'sent_at': DateTime.now()});
    });
  }

  Future<Map<String, dynamic>> uploadImage(File image) async {
    final List<String> mimeTypeData = lookupMimeType(image.path).split('/');
    final file = await http.MultipartFile.fromPath(
      'image',
      image.path,
      contentType: MediaType(
        mimeTypeData[0],
        mimeTypeData[1],
      ),
    );
    final http.MultipartRequest imageUploadRequest = http.MultipartRequest(
      'POST',
      Uri.parse(
        'https://us-central1-hchat-app.cloudfunctions.net/storeImage',
      ),
    );

    imageUploadRequest.files.add(file);

    try {
      final http.StreamedResponse streamedResponse =
          await imageUploadRequest.send();
      final http.Response response =
          await http.Response.fromStream(streamedResponse);
      if (response.statusCode != 200 && response.statusCode != 201) {
        return null;
      } else {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData;
      }
    } catch (error) {
      print(error);
      return null;
    }
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
