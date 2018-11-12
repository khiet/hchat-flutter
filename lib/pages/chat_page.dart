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
  StreamSubscription<QuerySnapshot> _chatSubscription;
  StreamSubscription<QuerySnapshot> _roomUserSubscription;
  MainInput _mainInput;
  Widget _roomNotification = Container();
  String _partnerName;
  String _partnerID;

  @override
  void initState() {
    print('[initState (ChatPage)]');
    super.initState();

    _setUserLocation();
    _chatSubscription = Firestore.instance
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
    print('[_chatStreamHandler]');
    final List<Chat> newChats = [];
    if (_chats.isNotEmpty) {
      newChats.addAll(_chats);
    }

    final WriteBatch batch = Firestore.instance.batch();
    snapshot.documentChanges.forEach((documentChange) {
      final DocumentSnapshot changedDocument = documentChange.document;

      if (changedDocument['read'] == false &&
          changedDocument['userID'] != widget.user.id) {
        batch.updateData(changedDocument.reference, {'read': true});
      }

      final chatIndex = newChats.indexWhere((chat) {
        return chat.id == changedDocument.documentID;
      });

      if (chatIndex == -1) {
        newChats.insert(
          0,
          Chat(
            id: changedDocument.documentID,
            text: changedDocument['text'],
            imageUrl: changedDocument['imageUrl'],
            username: changedDocument['username'],
            partnerName: changedDocument['partnerName'],
            createdAt: changedDocument['createdAt'],
            userID: changedDocument['userID'],
            read: changedDocument['read'],
          ),
        );
      } else {
        newChats.removeAt(chatIndex);
        newChats.insert(
          chatIndex,
          Chat(
            id: changedDocument.documentID,
            text: changedDocument['text'],
            imageUrl: changedDocument['imageUrl'],
            username: changedDocument['username'],
            partnerName: changedDocument['partnerName'],
            createdAt: changedDocument['createdAt'],
            userID: changedDocument['userID'],
            read: changedDocument['read'],
          ),
        );
      }
    });
    batch.commit();

    setState(() {
      _chats = newChats;
    });
  }

  void _chatInputHandler(String text) {
    _createChat({'text': text});
  }

  void _imageHandler(File image) async {
    final Map<String, dynamic> uploadedData = await _uploadImage(image);

    if (uploadedData != null) {
      _createChat({'imageUrl': uploadedData['imageUrl']});
    }
  }

  void _createChat(Map<String, dynamic> data) {
    Map<String, dynamic> defaultData = {
      'userID': widget.user.id,
      'username': widget.user.username,
      'partnerName': _partnerName,
      'partnerID': _partnerID,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    };

    data.addAll(defaultData);

    Firestore.instance
        .collection('rooms')
        .document(widget.roomID)
        .collection('chats')
        .add(data);
  }

  Future<Map<String, dynamic>> _uploadImage(File image) async {
    if (image == null) {
      // image was not picked
      return null;
    }

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
      if ((_partnerName == null || _partnerID == null) &&
          (document['userID'] != widget.user.id)) {
        _partnerName = document['username'];
        _partnerID = document['userID'];
      }

      print('[_partnerName] $_partnerName');
      print('[_partnerID] $_partnerID');
    });

    snapshot.documentChanges.forEach((DocumentChange documentChange) {
      Map<String, dynamic> changedData = documentChange.document.data;
      print(
        '[_roomUserStreamHandler (documentChange)] $changedData',
      );

      if (changedData['left'] == true) {
        if (changedData['username'] != widget.user.username) {
          setState(() {
            _roomNotification = _buildRoomNotification(
              context,
              '${changedData['username']} has left.',
              Theme.of(context).primaryColorLight,
            );
          });
        }
      } else {
        if (changedData['username'] != widget.user.username) {
          setState(() {
            _roomNotification = _buildRoomNotification(
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
    _chatSubscription.cancel();
    _roomUserSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('[build (ChatPage)]');

    return WillPopScope(
      onWillPop: () {
        // this will prevent swipe back: https://github.com/flutter/flutter/issues/14203
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
            _roomNotification,
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

  Widget _buildChatMessage(Chat chat) {
    Widget message = chat.isImageChat()
        ? ChatImage(imageUrl: chat.imageUrl)
        : ChatText(text: chat.text);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.0),
      child: ChatMessage(
        createdAt: chat.createdAt,
        username: chat.username,
        read: chat.read,
        message: message,
        myMessage: (chat.userID == widget.user.id),
      ),
    );
  }

  Widget _buildRoomNotification(
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
