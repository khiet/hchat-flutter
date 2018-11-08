import 'package:flutter/material.dart';

class ChatImage extends StatelessWidget {
  final String imageUrl;

  ChatImage({@required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: new BorderRadius.circular(8.0),
      child: FadeInImage.assetNetwork(
        width: 100.0,
        height: 100.0,
        placeholder: 'assets/placeholder.png',
        image: imageUrl,
        fadeInDuration: Duration(milliseconds: 400),
        fit: BoxFit.cover,
      ),
    );
  }
}
