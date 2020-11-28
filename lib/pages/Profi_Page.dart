import 'package:flutter/material.dart';
import 'package:meutcc/pages/hello_listView.dart';

class Profipage extends StatelessWidget {
  final Profissional profissional;
  Profipage(this.profissional);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(profissional.nome),
      ),
      body: Container(
        child: Image.asset(
          profissional.foto,
        ),
      ),
    );
  }
}
