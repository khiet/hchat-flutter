import 'package:flutter/material.dart';

import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../globals/constants.dart';

class User {
  User({@required this.id, @required this.username, @required this.fcmToken});

  final String id;
  final String username;
  final String fcmToken;

  String debugUsername() => '$username ($id)';

  static Future<User> findOrCreate() async {
    String userID = await _getUserID();
    String username = await _getUsername();
    String fcmToken = await _getFcmToken();

    return User(id: userID, username: username, fcmToken: fcmToken);
  }

  static Future<void> destroy() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userID');
    await prefs.remove('username');
    await prefs.remove('fcmToken');
  }

  static Future<String> _getUserID() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String prefUserID = prefs.get('userID');
    if (prefUserID == null) {
      prefUserID = Uuid().v4();
      await prefs.setString('userID', prefUserID);
    }

    return prefUserID;
  }

  static Future<String> _getUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String prefUsername = prefs.get('username');
    if (prefUsername == null) {
      prefUsername = (usernames..shuffle()).first;
      await prefs.setString('username', prefUsername);
    }

    return prefUsername;
  }

  static Future<String> _getFcmToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String fcmToken = prefs.get('fcmToken');
    if (fcmToken == null) {
      final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
      String token = await _firebaseMessaging.getToken();
      await prefs.setString('fcmToken', token);
    }

    print('[_getFcmToken] $fcmToken');
    return fcmToken;
  }
}
