import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class LoginPage extends StatelessWidget {
  final _tLogin = TextEditingController();
  final _tSenha = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("LOGIN"),
        centerTitle: true,
      ),
      body: _body(),
    );
  }
}

_body() {
  return Container(
    padding: EdgeInsets.all(20),
    child: ListView(
      children: [
        _text("Login", "Digite seu Usuário"),
        SizedBox(
          height: 25,
        ),
        _text("Senha", "Digite sua senha", password: true),
        SizedBox(
          height: 20,
        ),
        _button("Login")
      ],
    ),
  );
}

_text(String label, String hint,
    {bool password = false, TextEditingController controller}) {
  var textFormField = TextFormField(
    controller: controller,
    obscureText: password,
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontSize: 30,
        color: Colors.deepPurple,
      ),
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.blue,
        fontSize: 30,
      ),
    ),
  );
  return textFormField;
}

_button(String text) {
  return Container(
    height: 46,
    child: RaisedButton(
      color: Colors.blue,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 30,
        ),
      ),
      onPressed: () {},
    ),
  );
}
