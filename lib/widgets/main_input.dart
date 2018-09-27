import 'package:flutter/material.dart';

import 'chat_input.dart';

class MainInput extends StatefulWidget {
  MainInput({this.chatInputHandler});
  final Function chatInputHandler;

  @override
  State<StatefulWidget> createState() {
    return MainInputState();
  }
}

class MainInputState extends State<MainInput> {
  ChatInput _chatInput;

  @override
  void initState() {
    super.initState();

    _chatInput = ChatInput(onSubmitted: widget.chatInputHandler);
  }

  void bringUpCamera() {
    print('[bringUpCamera]');
  }

  void bringUpGallery() {
    print('[bringUpGallery]');
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        IconButton(
          icon: Icon(Icons.camera_alt),
          onPressed: () {
            bringUpCamera();
          },
        ),
        IconButton(
          icon: Icon(Icons.image),
          onPressed: () {
            bringUpGallery();
          },
        ),
        Flexible(
          child: _chatInput,
        ),
      ],
    );
  }
}
