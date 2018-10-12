import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class AdaptiveActivityIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Theme.of(context).platform == TargetPlatform.iOS
        ? CupertinoActivityIndicator()
        : CircularProgressIndicator();
  }
}
