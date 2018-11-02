import 'package:flutter/material.dart';

import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../globals/constants.dart';

class User {
  User({@required this.id, @required this.username});

  final String id;
  final String username;

  String debugUsername() => '$username ($id)';

  static Future<User> findOrCreate() async {
    String userID = await _getUserID();
    String username = await _getUsername();

    return User(id: userID, username: username);
  }

  static Future<void> destroy() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userID');
    await prefs.remove('username');
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
}
