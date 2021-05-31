import 'package:flutter/cupertino.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String avatar;

  const User({
    this.id,
    @required this.name,
    @required this.email,
    @required this.avatar,
 });
}
