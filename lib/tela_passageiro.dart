import 'package:demo_onibus/tela_pagamento.dart'; 
import 'package:flutter/material.dart';

class TelaPassageiro extends StatefulWidget {
  final String nomeUsuario;

  const TelaPassageiro({super.key, required this.nomeUsuario});

  @override
  State<TelaPassageiro> createState() => _TelaPassageiroState();
}

class _TelaPassageiroState extends State<TelaPassageiro> {
  double saldo = 20.00;

  void adicionarSaldo() {
    setState(() {
      saldo = saldo + 10.00;
    });
    print("Saldo atual após adicionar: $saldo");
  }

  Future<void> irParaPagamento() async {
    print("Saldo ANTES de ir para pagamento: $saldo");
    
    final novoSaldo = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TelaPagamento(
          saldoAtual: saldo,
          precoPassagem: 2,
          nomeUsuario: widget.nomeUsuario,
        ),
      ),
    );

    print("Valor retornado da TelaPagamento: $novoSaldo");

    if (novoSaldo != null && novoSaldo is double) {
      setState(() {
        saldo = novoSaldo;
      });
      print("Saldo ATUALIZADO após pagamento: $saldo");
    } else {
      print("Nenhum valor válido foi retornado ou pagamento foi cancelado");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Modo Passageiro - ${widget.nomeUsuario}'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Saldo: R\$ ${saldo.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
            ),
            
            const SizedBox(height: 30),

            SizedBox(
              width: 250,
              height: 80,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                onPressed: irParaPagamento,
                child: const Text('PAGAR PASSAGEM'),
              ),
            ),

            const SizedBox(height: 50),

            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.black,
                ),
                onPressed: adicionarSaldo,
                child: const Text('+ Adicionar R\$ 10,00'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}