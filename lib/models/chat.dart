import 'package:flutter/material.dart';

class Chat {
  Chat({
    @required this.text,
    @required this.imageUrl,
    @required this.username,
    @required this.createdAt,
  });

  final String text;
  final String imageUrl;
  final String username;
  final DateTime createdAt;

  String previewText() {
    return isImageChat() ? '$username sent an image.' : text;
  }

  bool isImageChat() => (imageUrl != null);
}
