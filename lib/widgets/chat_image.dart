import 'package:flutter/material.dart';

class ChatImage extends StatelessWidget {
  final String imageUrl;

  ChatImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100.0,
      height: 100.0,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.all(Radius.circular(10.0)),
      ),
    );
  }
}
