import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:location/location.dart' as geoloc;

import '../models/chat.dart';
import '../widgets/chat_message.dart';
import '../widgets/chat_text.dart';
import '../widgets/chat_image.dart';
import '../widgets/main_input.dart';
import '../models/user.dart';

class ChatPage extends StatefulWidget {
  final String roomID;
  final User user;

  ChatPage({
    @required this.roomID,
    @required this.user,
  });

  @override
  State<StatefulWidget> createState() {
    return ChatPageState();
  }
}

class ChatPageState extends State<ChatPage> {
  List<Chat> _chats = [];
  StreamSubscription<QuerySnapshot> _chastSubscription;
  StreamSubscription<QuerySnapshot> _roomUserSubscription;
  MainInput _mainInput;
  Widget _notification = Container();

  void chatStreamHandler(QuerySnapshot snapshot) {
    final List<Chat> newChats = [];
    for (DocumentSnapshot document in snapshot.documents) {
      newChats.insert(
        0,
        Chat(
          text: document['text'],
          imageUrl: document['imageUrl'],
          username: document['username'],
          createdAt: document['createdAt'],
        ),
      );
    }

    setState(() {
      _chats = newChats;
    });
  }

  void chatInputHandler(String text) {
    setDataFirestore({'text': text});
  }

  void imageHandler(File image) async {
    final Map<String, dynamic> uploadedData = await uploadImage(image);
    setDataFirestore({'imageUrl': uploadedData['imageUrl']});
  }

  void setDataFirestore(Map<String, dynamic> data) {
    Map<String, dynamic> defaultData = {
      'userID': widget.user.id,
      'username': widget.user.username,
      'createdAt': FieldValue.serverTimestamp()
    };

    data.addAll(defaultData);

    Firestore.instance
        .collection('rooms')
        .document(widget.roomID)
        .collection('chats')
        .add(data);
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

  void roomUserStreamHandler(QuerySnapshot snapshot) {
    snapshot.documents.forEach((DocumentSnapshot document) {
      print('[roomUserStreamHandler] ${document.data}');
    });

    snapshot.documentChanges.forEach((DocumentChange documentChange) {
      Map<String, dynamic> changedData = documentChange.document.data;
      print(
        '[roomUserStreamHandler (documentChange)] $changedData',
      );

      if (changedData['left'] == true) {
        if (changedData['username'] != widget.user.username) {
          setState(() {
            _notification = buildNotification(
                context, '${changedData['username']} has left.');
          });
        }
      } else {
        if (changedData['username'] != widget.user.username) {
          setState(() {
            _notification = buildNotification(
                context, '${changedData['username']} has joined.');
          });
        }
      }
    });
  }

  void leaveRoom() {
    print('[leaveRoom]');
    markUserAsLeft();
    if (_chats.isNotEmpty) {
      updateHistories(widget.roomID, _chats.first);
    }
  }

  void markUserAsLeft() {
    print('[markUserAsLeft]');
    Map<String, dynamic> data = {'left': true};

    Firestore.instance
        .collection('rooms')
        .document(widget.roomID)
        .collection('users')
        .document(widget.user.id)
        .updateData(data);
  }

  void updateHistories(String roomID, Chat lastChat) async {
    print('[updateHistories]');

    Map<String, dynamic> data = {
      'roomID': roomID,
      'lastChatPreviewText': lastChat.previewText(),
      'lastChatUsername': lastChat.username,
      'lastChatCreatedAt': lastChat.createdAt,
    };
    String userID = widget.user.id;

    QuerySnapshot fbHistories = await Firestore.instance
        .collection('histories')
        .where('roomID', isEqualTo: roomID)
        .getDocuments();

    if (fbHistories.documents.isEmpty) {
      data['userIDs'] = [userID];
      Firestore.instance.collection('histories').add(data);
    } else {
      List<dynamic> userIDs = fbHistories.documents.first['userIDs'];
      if (!userIDs.contains(userID)) {
        data['userIDs'] = List.from(userIDs)..add(userID);
      }

      fbHistories.documents.first.reference.updateData(data);
    }
  }

  void setUserLocation() async {
    final geoloc.Location location = geoloc.Location();
    try {
      final Map<String, double> currentLocation = await location.getLocation();
      print(
        '[currentLocation] ${currentLocation['latitude']} ${currentLocation['longitude']}',
      );
    } catch (error) {
      print('ERROR: ' + error);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('LOCATION UNAVAILABLE'),
            content: Text('CANNOT FETCH LOCATION'),
            actions: <Widget>[
              FlatButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              )
            ],
          );
        },
      );
    }
  }

  @override
  void dispose() {
    print('[dispose (ChatPage)]');
    _chastSubscription.cancel();
    _roomUserSubscription.cancel();
    super.dispose();
  }

  @override
  void initState() {
    print('[initState (ChatPage)]');
    super.initState();

    setUserLocation();
    _chastSubscription = Firestore.instance
        .collection('rooms')
        .document(widget.roomID)
        .collection('chats')
        .snapshots()
        .listen(chatStreamHandler);

    _roomUserSubscription = Firestore.instance
        .collection('rooms')
        .document(widget.roomID)
        .collection('users')
        .snapshots()
        .listen(roomUserStreamHandler);

    _mainInput = MainInput(
      chatInputHandler: chatInputHandler,
      imageHandler: imageHandler,
    );
  }

  @override
  Widget build(BuildContext context) {
    print('[build (ChatPage)]');

    return WillPopScope(
      onWillPop: () {
        leaveRoom();
        Navigator.of(context).pop();
        return Future.value(false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "HChat: ${widget.roomID}",
            style: Theme.of(context).textTheme.subhead,
          ),
          elevation:
              Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
        ),
        body: Column(
          children: <Widget>[
            _notification,
            Flexible(
              child: ListView.builder(
                padding: EdgeInsets.all(8.0),
                reverse: true,
                itemBuilder: (_, int index) {
                  return buildChatMessage(_chats[index]);
                },
                itemCount: _chats.length,
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

  ChatMessage buildChatMessage(Chat chat) {
    Widget message = chat.isImageChat()
        ? ChatImage(imageUrl: chat.imageUrl)
        : ChatText(text: chat.text);

    return ChatMessage(
      createdAt: chat.createdAt,
      username: chat.username,
      message: message,
    );
  }

  Container buildNotification(BuildContext context, String message) {
    return Container(
      color: Theme.of(context).accentColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            message,
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
