import 'package:flutter/material.dart';
import 'package:meutcc/pages/hello_listView.dart';
import 'package:meutcc/widgets/text.dart';

class Profipage extends StatelessWidget {
  final Profissional profissional;
  Profipage(this.profissional);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(profissional.nome),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.place),
            onPressed: _onClickMapa,
          ),
          IconButton(
            icon: Icon(Icons.videocam),
            onPressed: _onClickVideo,
          ),
          PopupMenuButton<String>(
            onSelected: (String value) => _onClickPopupMenu(
                value), // pode sucumbir o "(String value)" que tbm funciona
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: "Galeria",
                  child: Text("Galeria"),
                ),
                PopupMenuItem(
                  value: "Histórico",
                  child: Text("Histórico"),
                ),
                PopupMenuItem(
                  value: "Contato",
                  child: Text("Contactar"),
                )
              ];
            },
          )
        ],
      ),
      body: Container(
        child: ListView(
          children: [
            Image.asset(profissional.foto),
            _bloco1(),
            Divider(
              color: Colors.blue,
            ),
            _bloco2(),
          ],
        ),
      ),
    );
  }

  Row _bloco1() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            text(profissional.nome, fontSize: 25, bold: true),
            text(profissional.profissao, fontSize: 20),
          ],
        ),
        Row(children: <Widget>[
          IconButton(
            icon: Icon(
              Icons.favorite,
              color: Colors.red,
              size: 40,
            ),
            onPressed: _onClickFavorito,
          ),
          IconButton(
            icon: Icon(
              Icons.share,
              color: Colors.blue,
              size: 40,
            ),
            onPressed: _onClickFavorito,
          )
        ])
      ],
    );
  }

  _bloco2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 20,
        ),
        text(
          profissional.nome,
          fontSize: 16,
        ),
        SizedBox(
          height: 20,
        ),
        text(
            "A expressão Lorem ipsum em design gráfico e editoração é um texto padrão em latim utilizado na produção gráfica para preencher os espaços de texto em publicações para testar e ajustar aspectos visuais antes de utilizar conteúdo real.A expressão Lorem ipsum em design gráfico e editoração é um texto padrão em latim utilizado na produção gráfica para preencher os espaços de texto em publicações para testar e ajustar aspectos visuais antes de utilizar conteúdo real.A expressão Lorem ipsum em design gráfico e editoração é um texto padrão em latim utilizado na produção gráfica para preencher os espaços de texto em publicações para testar e ajustar aspectos visuais antes de utilizar conteúdo real.")
      ],
    );
  }

  void _onClickMapa() {}

  void _onClickVideo() {}

  _onClickPopupMenu(String value) {
    switch (value) {
      case "Galeria":
        print("Galeria");
        break;
      case "Histórico":
        print("Histórico");
        break;
      case "Contato":
        print("Contactar");
        break;
    }
  }

  void _onClickFavorito() {}
}
