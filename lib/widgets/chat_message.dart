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
      child:
          myMessage ? _buildMyMessage(context) : _buildPartnerMessage(context),
    );
  }

  Widget _buildPartnerMessage(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          margin: EdgeInsets.only(right: 10.0),
          child: CircleAvatar(
            child: Text(username[0]),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                username,
                style: Theme.of(context).textTheme.caption,
              ),
              Container(
                margin: EdgeInsets.only(top: 10.0),
                child: message,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMyMessage(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                username,
                style: Theme.of(context).textTheme.caption,
              ),
              Container(
                margin: EdgeInsets.only(top: 10.0),
                child: message,
              ),
            ],
          ),
        ),
        Container(
          margin: EdgeInsets.only(left: 10.0),
          child: CircleAvatar(
            child: Text(username[0]),
            backgroundColor: Theme.of(context).accentColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
