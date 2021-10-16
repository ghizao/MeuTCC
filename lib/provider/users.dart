import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:meutcc/data/dummy_users.dart';
import 'package:meutcc/models/user.dart';

class Users with ChangeNotifier {
  static const _baseUrl = "https://mechamou-tcc-default-rtdb.firebaseio.com/";
  final Map<String, User> _items = {...DUMMY_USERS};

  List<User> get all {
    return [..._items.values];
  }

  int get count {
    return _items.length;
  }

  User byIndex(int i) {
    return _items.values.elementAt(i);
  }

  // o métoddo abaixo é para adicionar um novo usuário
  Future<void> put(User user) async {
    if (user == null) {
      return;
    }

    if (user.id != null &&
        user.id.trim().isNotEmpty &&
        _items.containsKey(user.id)) {
      _items.update(
        user.id,
        (_) => User(
          id: user.id,
          name: user.name,
          email: user.email,
          avatar: user.avatar,
        ),
      );
    } else {
      final response = await http.post(
        "$_baseUrl/users.json",
        body: json.encode({
          'name': user.name,
          'email': user.email,
          'avatar': user.avatar,
        }),
      );

      final id = json.decode(response.body)['name'];
      print(json.decode(response.body));

      _items.putIfAbsent(
        id,
        () => User(
          id: id,
          name: user.name,
          email: user.email,
          avatar: user.avatar,
        ),
      );
    }

    notifyListeners();
  }

  void remove(User user) {
    if (user != null && user.id != null) {
      _items.remove(user.id);
      notifyListeners();
    }
  }
}
