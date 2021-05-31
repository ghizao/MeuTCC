import 'package:flutter/material.dart';
import 'package:meutcc/pages/login_page3.dart';

import 'utils/nav.dart';

class DrawerList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Drawer(
        child: ListView(
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: Text("meChamou.com"),
              accountEmail: Text("ghizao@gmail.com"),
              currentAccountPicture: CircleAvatar(
                backgroundImage: //AssetImage("assets/logo_trabalhador.jpg"),
                    NetworkImage(
                        "https://comps.canstockphoto.com.br/logo-p%C3%A1-trabalhador-3d-banco-de-ilustra%C3%A7%C3%B5es_csp37712676.jpg"),
              ),
            ),
            ListTile(
              leading: Icon(Icons.star),
              title: Text("Minha conta"),
              subtitle: Text("informações"),
              trailing: Icon(Icons.arrow_forward),
              onTap: () {
                print("chama alguma pagina ou função");
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.help),
              title: Text("Ajuda"),
              subtitle: Text("informações"),
              trailing: Icon(Icons.arrow_forward),
              onTap: () {
                print("chama alguma pagina ou função");
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.help),
              title: Text("Pagamento"),
              subtitle: Text("informações"),
              trailing: Icon(Icons.arrow_forward),
              onTap: () => _onClickLogout(context),
            ),
            ListTile(
              leading: Icon(Icons.help),
              title: Text("Logout"),
              subtitle: Text("Sair"),
              trailing: Icon(Icons.arrow_forward),
              onTap: () => _onClickLogout(context),
            ),
          ],
        ),
      ),
    );
  }

  _onClickLogout(BuildContext context) {
    Navigator.pop(context);
    push(
      context,
      LoginPage3(),
    );
  }
}
