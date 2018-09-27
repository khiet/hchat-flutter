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

  void bringUpCamera() {
    print('[bringUpCamera]');
  }

  Future bringUpGallery() async {
    print('[bringUpGallery]');

    File image = await ImagePicker.pickImage(
        source: ImageSource.gallery, maxWidth: maxImageWidth);

    widget.imageHandler(image);
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
