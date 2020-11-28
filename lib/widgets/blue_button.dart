import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class BlueButton extends StatelessWidget {
  String text;
  Function onPressed;
  Color color;
//esses aqui em cima são atributos

//esse comando abaixo é um construtor
  BlueButton(this.text, {@required this.onPressed, this.color = Colors.blue});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: RaisedButton(
          color: Colors.blue,
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          onPressed: onPressed),
    );
  }
}
