import 'package:flutter/material.dart';
import 'package:demo_onibus/tela_escolha.dart'; 

class TelaSenha extends StatefulWidget {
  const TelaSenha({super.key});

  @override
  State<TelaSenha> createState() => _TelaSenhaState();
}

class _TelaSenhaState extends State<TelaSenha> {
  final String _senhaCorreta = "123";
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _nomeController = TextEditingController();
  String _mensagemErro = "";
  bool _obscureText = true; 

  void _validarSenha() {
    if (_nomeController.text.trim().isEmpty) {
      setState(() {
        _mensagemErro = "Por favor, digite seu nome.";
      });
      return;
    }

    if (_senhaController.text == _senhaCorreta) {
      setState(() {
        _mensagemErro = "";
      });

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => TelaDeEscolha(
            nomeUsuario: _nomeController.text.trim(),
          ),
        ),
      );
    } else {
      setState(() {
        _mensagemErro = "Senha incorreta. Tente novamente.";
        _senhaController.clear(); 
      });
    }
  }

  @override
  void dispose() {
    _senhaController.dispose();
    _nomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900], 
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.lock_outline, size: 80, color: Colors.white),
              const SizedBox(height: 20),
              const Text("Acesso Restrito",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              
              TextField(
                controller: _nomeController,
                style: const TextStyle(color: Colors.white),
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: "Nome",
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color.fromARGB(25, 255, 255, 255), 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.person_outline, color: Colors.white70),
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: _senhaController,
                obscureText: _obscureText, 
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Senha",
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color.fromARGB(25, 255, 255, 255), 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.white70),
                    onPressed: () {
                      setState(() { _obscureText = !_obscureText; });
                    },
                  ),
                ),
                onSubmitted: (_) => _validarSenha(), 
              ),
              const SizedBox(height: 15),

              if (_mensagemErro.isNotEmpty)
                Text(_mensagemErro, textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 14)),
              const SizedBox(height: 15),

              ElevatedButton(
                onPressed: _validarSenha,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Entrar",
                  style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}