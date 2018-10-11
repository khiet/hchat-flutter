import 'package:flutter/material.dart';

class ChatMessage extends StatelessWidget {
  ChatMessage({this.message, this.username});
  final Widget message;
  final String username;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(right: 15.0),
            child: CircleAvatar(child: Text(username[0])),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(username, style: Theme.of(context).textTheme.subhead),
                Container(
                  margin: EdgeInsets.only(top: 10.0),
                  child: message,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
