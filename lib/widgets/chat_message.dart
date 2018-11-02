import 'package:flutter/material.dart';

class ChatMessage extends StatelessWidget {
  ChatMessage({
    @required this.message,
    @required this.username,
    @required this.createdAt,
    @required this.myMessage,
  });

  final Widget message;
  final String username;
  final DateTime createdAt;
  final bool myMessage;

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
            child: CircleAvatar(
              child: Text(username[0]),
              backgroundColor: myMessage
                  ? Theme.of(context).accentColor
                  : Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
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
