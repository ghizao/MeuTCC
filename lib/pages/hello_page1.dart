import 'package:flutter/material.dart';

class HelloPage1 extends StatefulWidget {
  @override
  _HelloPage1State createState() => _HelloPage1State();
}

class _HelloPage1State extends State<HelloPage1> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Page 1"),
      ),
    );
  }
}
