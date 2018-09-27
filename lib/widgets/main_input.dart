import 'dart:io';
import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';

import 'chat_input.dart';

class MainInput extends StatefulWidget {
  MainInput({this.chatInputHandler, this.imageHandler});
  final Function chatInputHandler;
  final Function imageHandler;

  @override
  State<StatefulWidget> createState() {
    return MainInputState();
  }
}

class MainInputState extends State<MainInput> {
  final double maxImageWidth = 400.0;

  ChatInput _chatInput;

  @override
  void initState() {
    super.initState();

    _chatInput = ChatInput(onSubmitted: widget.chatInputHandler);
  }

  Future<void> pickImage(ImageSource source) async {
    File image = await ImagePicker.pickImage(
      source: source,
      maxWidth: maxImageWidth,
    );

    widget.imageHandler(image);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        IconButton(
          icon: Icon(Icons.camera_alt),
          onPressed: () {
            pickImage(ImageSource.camera);
          },
        ),
        IconButton(
          icon: Icon(Icons.image),
          onPressed: () {
            pickImage(ImageSource.gallery);
          },
        ),
        Flexible(
          child: _chatInput,
        ),
      ],
    );
  }
}
