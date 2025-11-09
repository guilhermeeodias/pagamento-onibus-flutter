import 'package:flutter/material.dart';
import 'dart:math';

class TelaSucessoPagamento extends StatefulWidget {
  final double valorPago;
  final double novoSaldo;

  const TelaSucessoPagamento({
    super.key,
    required this.valorPago,
    required this.novoSaldo,
  });

  @override
  State<TelaSucessoPagamento> createState() => _TelaSucessoPagamentoState();
}

class _TelaSucessoPagamentoState extends State<TelaSucessoPagamento>
    with SingleTickerProviderStateMixin {
  late DateTime momentoTransacao;
  late String idTransacao;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    momentoTransacao = DateTime.now();
    idTransacao = _gerarIdAleatorio();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4CAF50), Color(0xFF388E3C), Color(0xFF2E7D32)],
          ),
        ),
        child: SafeArea(
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
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withAlpha(77), // 0.3
                              blurRadius: 40,
                              spreadRadius: 20,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          size: 90,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          const Text(
                            'APROVADO',
                            style: TextStyle(
                              fontSize: 46,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 3,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Pagamento realizado com sucesso',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withAlpha(230), // 0.9
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 50),

                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(38), // 0.15
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withAlpha(77), // 0.3
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              'Valor Pago:',
                              'R\$ ${widget.valorPago.toStringAsFixed(2)}',
                              Icons.receipt_rounded,
                            ),
                            const SizedBox(height: 20),
                            _buildInfoRow(
                              'Novo Saldo:',
                              'R\$ ${widget.novoSaldo.toStringAsFixed(2)}',
                              Icons.account_balance_wallet_rounded,
                            ),
                            const SizedBox(height: 20),
                            Divider(
                              color: Colors.white.withAlpha(77), // 0.3
                              thickness: 1,
                            ),
                            const SizedBox(height: 20),
                            _buildInfoRow(
                              'Data/Hora:',
                              _formatarDataHora(momentoTransacao),
                              Icons.access_time_rounded,
                              small: true,
                            ),
                            const SizedBox(height: 15),
                            _buildInfoRow(
                              'ID Transação:',
                              idTransacao,
                              Icons.qr_code_2_rounded,
                              small: true,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 50),

                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: double.infinity,
                        height: 65,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            colors: [Colors.white, Colors.white70],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(51), // 0.2
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop(true);
                          },
                          child: const Text(
                            'CONCLUIR',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4CAF50),
                              letterSpacing: 1,
                            ),
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
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {bool small = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(51), // 0.2
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: small ? 18 : 22),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: small ? 13 : 14,
                  color: Colors.white.withAlpha(204), // 0.8
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: small ? 14 : 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}