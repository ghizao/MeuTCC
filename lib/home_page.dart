import 'package:flutter/material.dart';
import 'package:meutcc/drawer_list.dart';
import 'package:meutcc/pages/hello_listView.dart';
import 'package:meutcc/pages/login_page.dart';
import 'package:meutcc/utils/nav.dart';
import 'package:meutcc/widgets/blue_button.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("MeChamou.com"),
        centerTitle: true,
      ),
      body: _body(context),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FloatingActionButton(
            heroTag: "btn1",
            child: Icon(Icons.add),
            onPressed: () {
              _onClickFab();
            },
          ),
          SizedBox(
            width: 30,
          ),
          FloatingActionButton(
            heroTag: "btn2",
            child: Icon(Icons.favorite),
            onPressed: () {
              _onClickFab();
            },
          ),
        ],
      ),
      drawer: DrawerList(),
    );
  }

  _onClickFab() {
    print("Adicionar");
  }

  _body(context) {
    return Container(
      padding: EdgeInsets.only(top: 16),
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          _text(),
          _pageView(),
          _buttons(),
        ],
      ),
    );
  }

  Container _pageView() {
    return Container(
      height: 350,
      child: PageView(
        children: <Widget>[
          _img("assets/execucoes/arqui2.jpg"),
          _img("assets/execucoes/desing1.jpg"),
          _img("assets/execucoes/eletrica2.jpg"),
          _img("assets/execucoes/fotografia1.jpg"),
          _img("assets/execucoes/eng2.jpg"),
          _img("assets/execucoes/cuidadora1.jpg"),
          _img("assets/execucoes/encana1.jpg"),
          _img("assets/execucoes/motores4.jpg"),
          _img("assets/execucoes/pintura1.jpg"),
          _img("assets/execucoes/pratos1.jpg"),
          _img("assets/execucoes/unhas2.jpg"),
          _img("assets/execucoes/cortes2.jpg"),
          _img("assets/execucoes/cortefem2.jpg"),
        ],
      ),
    );
  }

  _buttons() {
    return Builder(
      // ignore: missing_return
      builder: (context) {
        return Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                BlueButton("Login/Cadastro",
                    onPressed: () => _onClickNavigator(context, LoginPage())),
                BlueButton("Lista de Profissionais",
                    onPressed: () =>
                        _onClickNavigator(context, HelloListView())),

                /* BlueButton("Page 3",
                    onPressed: () => _onClickNavigator(context, HelloPage3())),*/
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                BlueButton("Snack", onPressed: () => _onClickSnack(context)),
                BlueButton("Acesso", onPressed: () => _onClickDialog(context)),
                // BlueButton("Toast", onPressed: _onClickToast)
              ],
            )
          ],
        );
      },
    );
  }

  _onClickSnack(context) {
    Scaffold.of(context).showSnackBar(
      SnackBar(
        content: Text("Faça o Login"),
        action: SnackBarAction(
          textColor: Colors.yellow,
          label: "ok",
          onPressed: () {
            print("OK!");
          },
        ),
      ),
    );
  }

  _onClickDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Bem Vindo ao maior protal de acesso a profissionais"),
            actions: <Widget>[
              FlatButton(
                child: Text("Sair"),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              FlatButton(
                child: Text("ok"),
                onPressed: () {
                  Navigator.pop(context);
                  print("ok!!!");
                },
              )
            ],
          );
        });
  }
}

_onClickToast() {}

// outra forma de fazer essa parto do código

void _onClickNavigator(BuildContext context, Widget page) async {
  String s = await push(context, page);
  print(">> $s");
}

//  void _onClickNavigator(BuildContext context, Widget page) async {
//   String s = await Navigator.push(context,
//        MaterialPageRoute(builder: (BuildContext context) {
//      return page;
//   }));

_img(String img) {
  return Container(
    margin: EdgeInsets.all(20),
    child: Image.asset(
      img,
      fit: BoxFit.cover,
    ),
  );
}

_text() {
  return Text(
    "Como posso ajudar?",
    style: TextStyle(
        fontSize: 40,
        color: Colors.blue,
        fontWeight: FontWeight.bold,
        fontStyle: FontStyle.italic,
        decoration: TextDecoration.underline,
        decorationColor: Colors.red),
  );
}
