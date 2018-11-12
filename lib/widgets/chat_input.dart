import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class ChatInput extends StatefulWidget {
  final Function onSubmitted;

  ChatInput({@required this.onSubmitted});

  @override
  State<StatefulWidget> createState() {
    return ChatInputState();
  }
}

class ChatInputState extends State<ChatInput> {
  final TextEditingController _textController = TextEditingController();
  bool _isSubmittable = false;

  void _handleSubmitted(String text) {
    if (_isSubmittable) {
      widget.onSubmitted(text);
      _textController.clear();

      setState(() {
        _isSubmittable = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('[ChatInput]');
    return IconTheme(
      data: IconThemeData(
        color: Theme.of(context).accentColor,
      ),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: <Widget>[
            buildTextField(),
            buildSendButton(context),
          ],
        ),
      ),
    );
  }

  Widget buildSendButton(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.0),
      child: Theme.of(context).platform == TargetPlatform.iOS
          ? CupertinoButton(
              child: Text("Send"),
              onPressed: _isSubmittable
                  ? () {
                      _handleSubmitted(_textController.text);
                      // dismiss keyboard
                      FocusScope.of(context).requestFocus(FocusNode());
                    }
                  : null,
            )
          : IconButton(
              icon: Icon(Icons.send),
              onPressed: _isSubmittable
                  ? () {
                      _handleSubmitted(_textController.text);
                      // dismiss keyboard
                      FocusScope.of(context).requestFocus(FocusNode());
                    }
                  : null,
            ),
    );
  }

  Widget buildTextField() {
    return Flexible(
      child: TextField(
        controller: _textController,
        onChanged: (String text) {
          print('[buildTextField] (onChanged) $text');

          setState(() {
            _isSubmittable = text.trim().isNotEmpty;
          });
        },
        // https://github.com/flutter/flutter/issues/22201
        autocorrect: false,
        onSubmitted: (String text) {
          print('[buildTextField] (onSubmitted) $text');
          _handleSubmitted(text);
        },
        decoration: InputDecoration.collapsed(hintText: "Send a message"),
      ),
    );
  }
}
