import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/chat_history.dart';
import '../models/user.dart';

class HistoryPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return HistoryPageState();
  }
}

class HistoryPageState extends State<HistoryPage> {
  User user;
  List<ChatHistory> _chatHistories = [];
  StreamSubscription<QuerySnapshot> _historySubscription;

  @override
  void initState() {
    print('[initState (HistoryPageState)]');
    super.initState();

    _fetchChatHistory();
  }

  void _fetchChatHistory() async {
    user = await User.findOrCreate();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String userID = prefs.get('userID');

    _historySubscription = Firestore.instance
        .collection('histories')
        .where('userIDs', arrayContains: userID)
        .snapshots()
        .listen(_historyStreamHandler);
  }

  void _historyStreamHandler(QuerySnapshot snapshot) {
    final List<ChatHistory> fetchedChatHistories = [];

    for (DocumentSnapshot history in snapshot.documents) {
      fetchedChatHistories.insert(
        0,
        ChatHistory(
          createdAt: history['lastChatCreatedAt'],
          previewText: history['lastChatPreviewText'],
          partnerName: (history['lastChatPartnerName'] == user.username)
              ? history['lastChatUsername']
              : history['lastChatPartnerName'],
          user: user,
          roomID: history['roomID'],
        ),
      );
    }

    setState(() {
      _chatHistories = fetchedChatHistories;
    });
  }

  @override
  void dispose() {
    print('[dispose (HistoryPageState)]');
    _historySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: (_chatHistories.length > 0)
          ? _buildChatHistoryList()
          : _buildNoHistoryPage(),
    );
  }

  Widget _buildNoHistoryPage() {
    return Center(
      child: Text(
        'No History',
        style: Theme.of(context).textTheme.title,
      ),
    );
  }

  Widget _buildChatHistoryList() {
    return ListView.builder(
      itemBuilder: (_, int index) {
        return Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(10.0),
              child: _chatHistories[index],
            ),
            Divider(height: 1.0),
          ],
        );
      },
      itemCount: _chatHistories.length,
    );
  }
}
