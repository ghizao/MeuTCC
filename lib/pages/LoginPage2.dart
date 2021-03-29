import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class LoginPage2 extends StatefulWidget {
  @override
  _LoginPage2State createState() => _LoginPage2State();
}

class _LoginPage2State extends State<LoginPage2> {
  final emailController = TextEditingController();
  final passController = TextEditingController();

  String email = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 60,
                child: CircleAvatar(
                  child: Text(
                    email.isEmpty ? 'A' : email[0].toUpperCase(),
                    style: TextStyle(fontSize: 24),
                  ),
                ),
              ),
              TextFormField(
                keyboardType: TextInputType.emailAddress,
                controller: emailController,
                onChanged: (value) {
                  setState(() {
                    email = value;
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  labelStyle: TextStyle(
                    fontSize: 30,
                    color: Colors.deepPurple,
                  ),
                  hintStyle: TextStyle(
                    color: Colors.blue,
                    fontSize: 30,
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                obscureText: true,
                controller: passController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  labelText: 'Insira sua senha',
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      child: RaisedButton(
                        color: Colors.blue,
                        onPressed: () => null,
                        child: Text(
                          'Prestador',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 16,
                  ),
                  Expanded(
                    child: Container(
                      height: 48,
                      child: RaisedButton(
                        color: Colors.blue,
                        onPressed: () => null,
                        child: Text(
                          'Contratante',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}