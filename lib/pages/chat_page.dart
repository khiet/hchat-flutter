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
import '../globals/constants.dart';

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
  String _partnerName;

  @override
  void initState() {
    print('[initState (ChatPage)]');
    super.initState();

    _setUserLocation();
    _chastSubscription = Firestore.instance
        .collection('rooms')
        .document(widget.roomID)
        .collection('chats')
        .snapshots()
        .listen(_chatStreamHandler);

    _roomUserSubscription = Firestore.instance
        .collection('rooms')
        .document(widget.roomID)
        .collection('users')
        .snapshots()
        .listen(_roomUserStreamHandler);

    _mainInput = MainInput(
      chatInputHandler: _chatInputHandler,
      imageHandler: _imageHandler,
    );
  }

  void _chatStreamHandler(QuerySnapshot snapshot) {
    final List<Chat> newChats = [];
    for (DocumentSnapshot document in snapshot.documents) {
      newChats.insert(
        0,
        Chat(
          text: document['text'],
          imageUrl: document['imageUrl'],
          username: document['username'],
          partnerName: document['partnerName'],
          createdAt: document['createdAt'],
          userID: document['userID'],
        ),
      );
    }

    setState(() {
      _chats = newChats;
    });
  }

  void _chatInputHandler(String text) {
    _setDataFirestore({'text': text});
  }

  void _imageHandler(File image) async {
    final Map<String, dynamic> uploadedData = await _uploadImage(image);
    _setDataFirestore({'imageUrl': uploadedData['imageUrl']});
  }

  void _setDataFirestore(Map<String, dynamic> data) {
    Map<String, dynamic> defaultData = {
      'userID': widget.user.id,
      'username': widget.user.username,
      'partnerName': _partnerName,
      'createdAt': FieldValue.serverTimestamp()
    };

    data.addAll(defaultData);

    Firestore.instance
        .collection('rooms')
        .document(widget.roomID)
        .collection('chats')
        .add(data);
  }

  Future<Map<String, dynamic>> _uploadImage(File image) async {
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
      Uri.parse(imageUploadUrl),
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
      return null;
    }
  }

  void _roomUserStreamHandler(QuerySnapshot snapshot) {
    snapshot.documents.forEach((DocumentSnapshot document) {
      print('[_roomUserStreamHandler] ${document.data}');
      if (_partnerName == null && (document['userID'] != widget.user.id)) {
        _partnerName = document['username'];
      }

      print('[_partnerName] $_partnerName');
    });

    snapshot.documentChanges.forEach((DocumentChange documentChange) {
      Map<String, dynamic> changedData = documentChange.document.data;
      print(
        '[_roomUserStreamHandler (documentChange)] $changedData',
      );

      if (changedData['left'] == true) {
        if (changedData['username'] != widget.user.username) {
          setState(() {
            _notification = _buildNotification(
              context,
              '${changedData['username']} has left.',
              Theme.of(context).primaryColorLight,
            );
          });
        }
      } else {
        if (changedData['username'] != widget.user.username) {
          setState(() {
            _notification = _buildNotification(
              context,
              '${changedData['username']} has joined.',
              Theme.of(context).primaryColorDark,
            );
          });
        }
      }
    });
  }

  @override
  void dispose() {
    print('[dispose (ChatPage)]');
    _chastSubscription.cancel();
    _roomUserSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('[build (ChatPage)]');

    return WillPopScope(
      onWillPop: () {
        _leaveRoom();
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
                reverse: true,
                itemBuilder: (_, int index) {
                  return _buildChatMessage(_chats[index]);
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

  void _leaveRoom() {
    print('[_leaveRoom]');
    _markUserAsLeft();
    if (_chats.isNotEmpty) {
      _updateHistories(widget.roomID, _chats.first);
    }
  }

  void _markUserAsLeft() async {
    print('[_markUserAsLeft]');
    final Map<String, dynamic> data = {'left': true};

    final QuerySnapshot fbQsRoomUser = await Firestore.instance
        .collection('rooms')
        .document(widget.roomID)
        .collection('users')
        .where('userID', isEqualTo: widget.user.id)
        .getDocuments();

    fbQsRoomUser.documents.forEach((DocumentSnapshot user) {
      user.reference.updateData(data);
    });
  }

  void _updateHistories(String roomID, Chat lastChat) async {
    print('[_updateHistories]');

    Map<String, dynamic> data = {
      'roomID': roomID,
      'lastChatPreviewText': lastChat.previewText(),
      'lastChatUsername': lastChat.username,
      'lastChatPartnerName': lastChat.partnerName,
      'lastChatCreatedAt': lastChat.createdAt,
    };
    final String userID = widget.user.id;

    final QuerySnapshot fbHistories = await Firestore.instance
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

  Widget _buildChatMessage(Chat chat) {
    Widget message = chat.isImageChat()
        ? ChatImage(imageUrl: chat.imageUrl)
        : ChatText(text: chat.text);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.0),
      child: ChatMessage(
        createdAt: chat.createdAt,
        username: chat.username,
        message: message,
        myMessage: (chat.userID == widget.user.id),
      ),
    );
  }

  Widget _buildNotification(
    BuildContext context,
    String message,
    Color bgColor,
  ) {
    return Container(
      color: bgColor,
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

  void _setUserLocation() async {
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
}
