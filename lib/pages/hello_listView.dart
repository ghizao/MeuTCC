import 'package:flutter/material.dart';
import 'package:meutcc/pages/Profi_Page.dart';
import 'package:meutcc/utils/nav.dart';

class Profissional {
  String nome;
  String foto;
  String profissao;

  Profissional(this.nome, this.foto, this.profissao);
}

class HelloListView extends StatefulWidget {
  @override
  _HelloListViewState createState() => _HelloListViewState();
}

class _HelloListViewState extends State<HelloListView> {
  bool _gridView = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ListView"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.list),
            onPressed: () {
              print("lista");
              setState(() {
                _gridView = false;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.grid_on),
            onPressed: () {
              print("Grid");
              setState(() {
                _gridView = true;
              });
            },
          ),
        ],
      ),
      body: _body(),
    );
  }

  _body() {
    List<Profissional> profissionais = [
      Profissional("Rose", "assets/avatar/engenheira.png", "Engenheira"),
      Profissional("Dr. Macedo", "assets/avatar/advogado.png", "Advogado"),
      Profissional("Juliana", "assets/avatar/enfermeira2.png", "Enfermeira"),
      Profissional("Carlos", "assets/avatar/construtor.png", "Construtor"),
      Profissional("Norma", "assets/avatar/chef.png", "Chef"),
      Profissional("Leandro", "assets/avatar/barbeiro.png", "Barbeiro"),
      Profissional("Flavia", "assets/avatar/contadora.png", "Contaodra"),
      Profissional("Gilmar", "assets/avatar/eletricista.png", "Eletricista"),
      Profissional("Fernanda", "assets/avatar/Manicure.png", "Manicure"),
      Profissional("Joseval", "assets/avatar/encanador.png", "encanador"),
      Profissional("Wesley", "assets/avatar/fotografo.png", "Fotógrafo"),
      Profissional("Nilton", "assets/avatar/mecanico.png", "Mecânico"),
      Profissional("Edinho", "assets/avatar/pintor.png", "Pintor")
    ];

    if (_gridView) {
      return GridView.builder(
        gridDelegate:
            SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
        itemCount: profissionais.length,
        itemBuilder: (context, index) {
          return _itemView(profissionais, index);
        },
      );
    } else {
      return ListView.builder(
        itemExtent: 350,
        itemCount: profissionais.length,
        itemBuilder: (context, index) {
          return _itemView(profissionais, index);
        },
      );
    }
  }

  _itemView(List<Profissional> profissionais, int index) {
    Profissional profissional = profissionais[index];

    return GestureDetector(
      onTap: () {
        push(context, Profipage(profissional));
      },
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _img(profissional.foto),
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              margin: EdgeInsets.all(10),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                profissional.nome,
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
              
            ),
          ),
        ],
      ),
    );
  }

  _img(String img) {
    return Image.asset(
      img,
      fit: BoxFit.cover,
    );
  }
}
