import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController _textController = TextEditingController();
  final bool _isComposing = true;
  final Function onSubmitted;

  ChatInput({this.onSubmitted});

  void _handleSubmitted(String text) {
    onSubmitted(text);
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    print('build inside ChatInput');
    return IconTheme(
      data: IconThemeData(
        color: Theme.of(context).accentColor,
      ),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: <Widget>[
            Flexible(
              child: TextField(
                controller: _textController,
                onChanged: (String text) {},
                onSubmitted: (String text) {
                  _handleSubmitted(text);
                },
                decoration:
                    InputDecoration.collapsed(hintText: "Send a message"),
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 4.0),
              child: Theme.of(context).platform == TargetPlatform.iOS
                  ? CupertinoButton(
                      child: Text("Send"),
                      onPressed: _isComposing
                          ? () => _handleSubmitted(_textController.text)
                          : null,
                    )
                  : IconButton(
                      icon: Icon(Icons.send),
                      onPressed: _isComposing
                          ? () => _handleSubmitted(_textController.text)
                          : null,
                    ),
            )
          ],
        ),
      ),
    );
  }
}
