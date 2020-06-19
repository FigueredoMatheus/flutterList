import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main(){
  runApp(MaterialApp(
    home: App(),
  ));
}

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
//Lista q as tarefas serão armazenadas
  List _toDoList = [];

  TextEditingController _toDoController = TextEditingController();

  //Necessarios para a feature de desfazer um item que foi removido
  //Item que sera removido
  Map<String, dynamic> _lastRemoved;
  //Posição que o item estava quando foi removido
  int _lastRemovedPos;

  //Método que sempre é chamado quando o estado da tela é alterado(quando o app abrir por exemplo)
  @override
  void initState() {
    super.initState();
    //Leu o arquivo dps passa a String de retorno para data
    _readData().then((data) {
      setState(() {
        //Transformando a String recebida em um JSON;
        _toDoList = json.decode(data);
      });
    });
  }

  void _addToDo(){
    setState(() {
      Map<String, dynamic> newToDo = Map();
      newToDo["title"] = _toDoController.text;
      _toDoController.text = "";

      newToDo["ok"] = false;
      _toDoList.add(newToDo);
      _saveData();
    });
  }
//Future para que n seja atualizado de imediato
  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));
    /*
    retorna 1 se a > b
    retorn 0 se a == b
    return -1 se b > a
     */
    setState(() {
      _toDoList.sort( (a,b){
        if(a["ok"] && !b["ok"])
          return 1;
        else if(!a["ok"] && b["ok"])
          return -1;
        else{
          return 0;
        }
      });

      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
//Lista n precisa ser SingleScroll pq ja ta incluido
      body: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: <Widget>[
            Container(
              padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
              child: Row(
                children: <Widget>[
                  //O child erá expandir o maximo, nesse caso, ate o botão
                  Expanded(
                    child: TextField(
                      controller: _toDoController,
                      keyboardType: TextInputType.text,
                      cursorColor: Colors.blue,
                      decoration: InputDecoration(
                        labelText: "Nova Tarefa",
                        labelStyle: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ),

                  RaisedButton(
                    padding: EdgeInsets.only(left: 10.0),
                    color: Colors.blue,
                    child: Text("Add",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 16.0)
                    ),
                    onPressed:() {
                      if(!_toDoController.text.isEmpty)
                          _addToDo();
                    },
                  )
                ],
              ),
            ),
//Uma lista n pode ser Scrollable
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                  padding: EdgeInsets.only(top: 10.0),
                  itemCount: _toDoList.length,
                  itemBuilder: buildItem,),
              ),
            )
          ],
        ),

    );
  }

  //Index é a posição do item corrente que está sendo manipulado
  Widget buildItem(BuildContext context, int index){
    //Permite apagar um conteudo
      return Dismissible(
        //Key para saber qual elemento sera apagado
        key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
        //Container pois se deseja marcar todo o quadrado em baixo e vermelho
        background: Container(
          color: Colors.red,
          child: Align(
            //Vai de -1 a 1
            alignment: Alignment(-0.9, 0.0),
            child: Icon(Icons.delete, color: Colors.white,),
          ),
        ),
        direction: DismissDirection.startToEnd,
        child:  CheckboxListTile(
          //Recebe um bool pra saber se a box foi marcada
            onChanged: (check){
              setState(() {
                _toDoList[index]["ok"] = check;
                _saveData();
              });
            },
            title: Text(_toDoList[index]["title"]),
            value: _toDoList[index]["ok"], //Se esta checado ou n
            secondary: CircleAvatar(
              child: Icon(_toDoList[index]["ok"] ?
              Icons.check : Icons.error),
            )
        ),
        //Chamado toda vez que um item for removido
        onDismissed: (direction) {
          setState(() {
            _lastRemoved = Map.from(_toDoList[index]);
            _lastRemovedPos = index;
            _toDoList.removeAt(index);
            _saveData();

            final snack = SnackBar(
              content: Text("Tarefa \"${_lastRemoved["title"]}\" removida"),
              action: SnackBarAction(
                label: "Desfazer",
                onPressed: () {
                  setState(() {
                    _toDoList.insert(_lastRemovedPos, _lastRemoved);
                    _saveData();
                  });
                },
              ),
              duration: Duration(seconds: 2),
            );

            Scaffold.of(context).showSnackBar(snack);
          });
        },
      );
  }


  Future<File> _getFile() async {
    //pasta é o diretório onde os documentos do app podem ser gravados no celular
    //O comando n é executado instataneamente por isso tem q usar await
    final pasta = await getApplicationDocumentsDirectory();
    return File("${pasta.path}/data.json");
  }
//Tudo q envolve leitura e salvamento de arquivos não acontece instataneamente por isso tem q ser async
  Future<File> _saveData() async {
    //Transforma um arquivo json é uma unica string
    String data = json.encode(_toDoList);
    print(data);
    //Como era retornado um valor futuro, usa-se await
    final file = await _getFile();
    //escrevendo os arquivos na pasta
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try{
      final file = await _getFile();
       await file.readAsString();
      print(await file.readAsString());
      return file.readAsString();
    }catch(e ){
      return null;
    }
  }

}

