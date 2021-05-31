import 'package:flutter/material.dart';

Future push(BuildContext context, Widget page, {bool replace}) {
  return Navigator.push(context,
      MaterialPageRoute(builder: (BuildContext context) {
    return page;
  }));
}
