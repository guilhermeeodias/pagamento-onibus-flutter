import 'package:flutter/material.dart';
import 'package:demo_onibus/tela_passageiro.dart';
import 'package:demo_onibus/tela_motorista.dart';
import 'package:demo_onibus/tela_creditos.dart';

class TelaDeEscolha extends StatefulWidget {
  final String nomeUsuario;

  const TelaDeEscolha({super.key, required this.nomeUsuario});

  @override
  State<TelaDeEscolha> createState() => _TelaDeEscolhaState();
}

class _TelaDeEscolhaState extends State<TelaDeEscolha> {
  int _contadorTaps = 0;
  DateTime? _ultimoTap;

  void _contarTaps() {
    final agora = DateTime.now();
    
    if (_ultimoTap != null && agora.difference(_ultimoTap!).inSeconds > 2) {
      _contadorTaps = 0;
    }
    
    _ultimoTap = agora;
    _contadorTaps++;

    if (_contadorTaps >= 6) {
      _contadorTaps = 0;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TelaCreditos()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _contarTaps,
          child: const Text('Projeto Demo Bluetooth'),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 250, 
              height: 80, 
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent, 
                  foregroundColor: Colors.white, 
                  textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TelaPassageiro(
                        nomeUsuario: widget.nomeUsuario,
                      ),
                    ),
                  );
                },
                child: const Text('Sou PASSAGEIRO'),
              ),
            ),
            
            const SizedBox(height: 40), 

            SizedBox(
              width: 250, 
              height: 80, 
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, 
                  foregroundColor: Colors.white, 
                  textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TelaMotorista()),
                  );
                },
                child: const Text('Sou MOTORISTA'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}