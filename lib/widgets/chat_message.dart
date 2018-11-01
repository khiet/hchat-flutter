import 'package:flutter/material.dart';

class ChatMessage extends StatelessWidget {
  ChatMessage({this.message, this.username, this.createdAt});
  final Widget message;
  final String username;
  final DateTime createdAt;

  @override
  Widget build(BuildContext context) {
    print('[build (ChatMessage)] $message $username $createdAt');
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(right: 15.0),
            child: CircleAvatar(child: Text(username[0])),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                username,
                style: Theme.of(context).textTheme.subhead,
              ),
              Container(
                margin: EdgeInsets.only(top: 10.0),
                child: message,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
