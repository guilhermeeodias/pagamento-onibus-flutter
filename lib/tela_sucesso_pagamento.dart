import 'package:flutter/material.dart';
import 'dart:math';

class TelaSucessoPagamento extends StatelessWidget {
  final double valorPago;
  final double novoSaldo;
  final DateTime momentoTransacao;
  final String idTransacao;

  TelaSucessoPagamento({
    super.key,
    required this.valorPago,
    required this.novoSaldo,
  })  : momentoTransacao = DateTime.now(),
        idTransacao = _gerarIdAleatorio();

  static String _gerarIdAleatorio() {
    final random = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(12, (index) => chars[random.nextInt(chars.length)]).join();
  }

  String _formatarDataHora(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year} às ${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}:${data.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 60,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 80,
                      color: Colors.green,
                    ),
                  ),

                  const SizedBox(height: 40),

                  const Text(
                    'APROVADO',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 50),

                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow('Valor Pago:', 'R\$ ${valorPago.toStringAsFixed(2)}'),
                        const SizedBox(height: 15),
                        _buildInfoRow('Novo Saldo:', 'R\$ ${novoSaldo.toStringAsFixed(2)}'),
                        const SizedBox(height: 15),
                        const Divider(color: Colors.white70, thickness: 1),
                        const SizedBox(height: 15),
                        _buildInfoRow('Data/Hora:', _formatarDataHora(momentoTransacao)),
                        const SizedBox(height: 15),
                        _buildInfoRow('ID Transação:', idTransacao),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                      child: const Text(
                        'SAIR',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}