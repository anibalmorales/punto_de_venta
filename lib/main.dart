import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'constantes.dart';
import 'navigator.dart';

Future _guardarToken(String token) async {
  log("Estoy guardando el token...");
  final prefs = await SharedPreferences.getInstance();
  prefs.setString("token_api", token);
  log("Terminado de guardar token");
}

void main() => runApp(MyApp());

Future<String> hacerLogin(String email, String password) async {
  final http.Response response = await http.post(
    rutaLogin,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      'email': email,
      'password': password,
    }),
  );
  if (response.statusCode == 200) {
    Map<String, dynamic> j = json.decode(response.body);
    var token = j["access_token"];
    _guardarToken(token);

    return token;
  } else {
    throw Exception('Datos incorrectos');
  }
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Punto de venta',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Inicio de sesión'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<bool> login(String usuario, String password) async {
    setState(() {
      cargandoBoton = true;
    });

    final http.Response response = await http.post(
      rutaLogin,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': usuario,
        'password': password,
      }),
    );
    setState(() {
      this.cargandoBoton = false;
    });
    if (response.statusCode == 200) {
      Map<String, dynamic> respuesta = json.decode(response.body);
      var token = respuesta["access_token"];
      await _guardarToken(token);
      return true;
    }
    return false;
  }

  Future<bool> _revisarSiTokenEsValido() async {
    setState(() {
      this.cargandoGeneralmente = true;
    });
    final prefs = await SharedPreferences.getInstance();
    String posibleToken = prefs.getString("token_api");
    if (posibleToken == null) {
      return false;
    }
    final http.Response response =
        await http.get('$RUTA_API/user', headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $posibleToken',
    });
    setState(() {
      this.cargandoGeneralmente = false;
    });

    return response.statusCode == 200;
  }

  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool cargandoGeneralmente = false;
  bool cargandoBoton = false;

  @override
  void initState() {
    super.initState();
    this.navegarAEscritorioSiEsPosible();
  }

  void navegarAEscritorioSiEsPosible() async {
    var respuesta = await _revisarSiTokenEsValido();
    if (respuesta) navegarAEscritorio();
    log("La respuesta es:" + respuesta.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: cargandoGeneralmente
            ? CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _email,
                      decoration: InputDecoration(
                          hintText: 'correo@dominio',
                          labelText: "Correo electrónico"),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _password,
                      decoration: InputDecoration(
                          hintText: 'Contraseña', labelText: 'Contraseña'),
                      obscureText: true, /* <-- Aquí */
                    ),
                  ),
                  Builder(
                    builder: (context) => RaisedButton(
                      color: Colors.blue,
                      textColor: Colors.white,
                      child: cargandoBoton
                          ? CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : Text('Iniciar sesión'),
                      onPressed: () async {
                        bool respuesta =
                            await login(_email.text, _password.text);
                        if (respuesta) {
                          navegarAEscritorio();
                        } else {
                          Scaffold.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Datos incorrectos. Intenta de nuevo'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
