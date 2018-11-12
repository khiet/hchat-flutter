import 'package:flutter/material.dart';

import '../pages/chat_image_page.dart';

class ChatImage extends StatelessWidget {
  final String imageUrl;

  ChatImage({@required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _goToChatPage(context);
      },
      child: ClipRRect(
        borderRadius: new BorderRadius.circular(8.0),
        child: FadeInImage.assetNetwork(
          width: 100.0,
          height: 100.0,
          placeholder: 'assets/placeholder.png',
          image: imageUrl,
          fadeInDuration: Duration(milliseconds: 400),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  void _goToChatPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) => ChatImagePage(
              imageWidget: Image(
                image: NetworkImage(imageUrl),
              ),
            ),
      ),
    );
  }
}
