import 'package:flutter/material.dart';
import 'package:meutcc/provider/users.dart';
import 'package:meutcc/routes/app_routes.dart';
import 'package:meutcc/views/user_form.dart';
import 'package:meutcc/views/user_list.dart';
import 'package:provider/provider.dart';
import 'home_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (ctx) => Users(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: Colors.blue,
        ),
        home: HomePage(),
        routes: {AppRoutes.USER_FORM: (_) => UserForm()},
      ),
    );
  }
}
