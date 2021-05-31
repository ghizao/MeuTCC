import 'package:flutter/material.dart';
import 'package:meutcc/models/user.dart';
import 'package:meutcc/provider/users.dart';
import 'package:provider/provider.dart';

class UserForm extends StatefulWidget {
  @override
  _UserFormState createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  final _form = GlobalKey<FormState>();

  final Map<String, String> _formData = {};

  void _loadFormData(User user) {
    if (user != null) {
      _formData['id'] = user.id;
      _formData['name'] = user.name;
      _formData['E-mail'] = user.email;
      _formData['avatar'] = user.avatar;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final User user = ModalRoute.of(context).settings.arguments;
    _loadFormData(user);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Formulário de Cadastro'),
          actions: [
            IconButton(
              icon: Icon(Icons.save),
              onPressed: () {
                final isValid = _form.currentState.validate();

                if (isValid) {
                  _form.currentState.save();
                  Provider.of<Users>(context, listen: false).put(
                    User(
                      id: _formData['id'],
                      name: _formData['name'],
                      email: _formData['E-mail'],
                      avatar: _formData['avatar'],
                    ),
                  );
                  Navigator.of(context).pop();
                }
              },
            )
          ],
        ),
        body: Padding(
          padding: EdgeInsets.all(10),
          child: Form(
              key: _form,
              child: Column(children: <Widget>[
                TextFormField(
                  initialValue: _formData['name'],
                  decoration: InputDecoration(labelText: 'nome'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nome Invalido - Favor digitar o nome do Usuário';
                    }

                    if (value.trim().length < 5) {
                      return 'Nome muito pequeno - No mínimo 5 Letras';
                    }

                    return null;
                  },
                  onSaved: (value) => _formData['name'] = value,
                ),
                TextFormField(
                  initialValue: _formData['E-mail'],
                  decoration: InputDecoration(labelText: 'E-mail'),
                  onSaved: (value) => _formData['E-mail'] = value,
                ),
                TextFormField(
                  initialValue: _formData['avatar'],
                  decoration: InputDecoration(labelText: 'foto'),
                  onSaved: (value) => _formData['avatar'] = value,
                ),
              ])),
        ));
  }
}
