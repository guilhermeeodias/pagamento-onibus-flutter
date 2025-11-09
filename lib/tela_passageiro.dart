import 'package:demo_onibus/tela_pagamento.dart';
import 'package:demo_onibus/tela_historico_completo.dart';
import 'package:demo_onibus/transaction_list.dart';
import 'package:demo_onibus/main.dart';
import 'package:flutter/material.dart';

class TelaPassageiro extends StatefulWidget {
  final String nomeUsuario;

  const TelaPassageiro({super.key, required this.nomeUsuario});

  @override
  State<TelaPassageiro> createState() => _TelaPassageiroState();
}

class _TelaPassageiroState extends State<TelaPassageiro> with SingleTickerProviderStateMixin {
  double saldo = 20.00;
  List<Map<String, dynamic>> historico = [];
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();
    
    _carregarDados();
  }
  
  Future<void> _carregarDados() async {
    final historicoSalvo = await StorageHelper.carregarHistorico();
    setState(() {
      if (historicoSalvo.isEmpty) {
        // Histórico inicial se não houver dados salvos
        
        // <-- CORREÇÃO 1 (Como você já tinha feito)
        historico = <Map<String, dynamic>>[
          {
            'tipo': 'recarga',
            'valor': 10.00,
            'data': 'Ontem, 12:00',
          },
          {
            'tipo': 'pagamento',
            'valor': -2.00,
            'data': 'Ontem, 17:04',
          },
        ];
      } else {
        historico = historicoSalvo;
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void adicionarSaldo() async {
    setState(() {
      saldo = saldo + 10.00;
      historico.insert(0, {
        'tipo': 'recarga',
        'valor': 10.00,
        'data': 'Hoje, ${_getHoraAtual()}',
      } as Map<String, dynamic>); // <-- CORREÇÃO 2: Forçar o tipo do mapa
    });
    await StorageHelper.salvarHistorico(historico);
    print("Saldo atual após adicionar: $saldo");
  }

  String _getHoraAtual() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
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
        historico.insert(0, {
          'tipo': 'pagamento',
          'valor': -2.00,
          'data': 'Hoje, ${_getHoraAtual()}',
        } as Map<String, dynamic>); // <-- CORREÇÃO 3: Forçar o tipo do mapa (Onde dava o erro)
      });
      await StorageHelper.salvarHistorico(historico);
      print("Saldo ATUALIZADO após pagamento: $saldo");
    } else {
      print("Nenhum valor válido foi retornado ou pagamento foi cancelado");
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (O RESTO DO SEU MÉTODO build CONTINUA IGUAL)
    // ... (NENHUMA MUDANÇA DAQUI PARA BAIXO)
    final isDark = AppTheme.isDark(context);
    int viagensRestantes = (saldo / 2).floor();
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor(context),
                        borderRadius: BorderRadius.circular(10),
                        border: isDark ? null : Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: AppTheme.textColor(context),
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Olá, ${widget.nomeUsuario}!',
                            style: TextStyle(
                              color: AppTheme.textColor(context),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Pronto para a sua próxima viagem?',
                            style: TextStyle(
                              color: AppTheme.textSecondaryColor(context),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor(context),
                        borderRadius: BorderRadius.circular(10),
                        border: isDark ? null : Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.settings_outlined,
                        color: AppTheme.textSecondaryColor(context),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor(context),
                        borderRadius: BorderRadius.circular(10),
                        border: isDark ? null : Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(
                          isDark ? Icons.light_mode : Icons.dark_mode,
                          color: AppTheme.textSecondaryColor(context),
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          setState(() {
                            AppTheme.toggleTheme();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Card de Saldo
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primaryBlue, AppTheme.primaryBlueLight],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SEU SALDO ATUAL',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'R\$ ${saldo.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.confirmation_number_outlined,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Você ainda pode fazer $viagensRestantes viagens.',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Botões de ação
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              icon: Icons.qr_code_scanner,
                              label: 'Pagar Passagem',
                              color: AppTheme.primaryBlue,
                              onTap: irParaPagamento,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildActionButton(
                              icon: Icons.add,
                              label: 'Adicionar Saldo',
                              color: isDark ? const Color(0xFF273449) : const Color(0xFFE2E8F0),
                              onTap: adicionarSaldo,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Histórico de Pagamentos
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Histórico de Pagamentos',
                          style: TextStyle(
                            color: AppTheme.textColor(context),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Lista de histórico (apenas 6 primeiros)
                      ...historico.take(6).map((item) => _buildHistoricoItem(item)),
                      
                      // Botão Ver Mais
                      if (historico.length > 6)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TelaHistoricoCompleto(
                                      historico: historico,
                                    ),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primaryBlue,
                                side: BorderSide(
                                  color: isDark 
                                      ? AppTheme.primaryBlue.withAlpha(77)
                                      : AppTheme.primaryBlue,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Ver Todas (${historico.length})',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = AppTheme.isDark(context);
    final isBlueButton = color == AppTheme.primaryBlue;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: !isDark && !isBlueButton ? Border.all(
            color: const Color(0xFFCBD5E1),
            width: 1,
          ) : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isBlueButton 
                  ? Colors.white
                  : (isDark ? Colors.white : AppTheme.primaryBlue),
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isBlueButton 
                    ? Colors.white
                    : (isDark ? Colors.white : AppTheme.lightText),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoricoItem(Map<String, dynamic> item) {
    final isDark = AppTheme.isDark(context);
    final isPagamento = item['tipo'] == 'pagamento';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1f2937) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isDark ? null : Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isPagamento 
                  ? AppTheme.errorRed.withAlpha(26)
                  : AppTheme.primaryBlue.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPagamento ? Icons.arrow_upward : Icons.credit_card,
              color: isPagamento ? AppTheme.errorRed : AppTheme.primaryBlue,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPagamento ? 'Pagamento Aprovado' : 'Recarga de Saldo',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.textColor(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item['data'],
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${item['valor'] > 0 ? '+' : ''} R\$ ${item['valor'].abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isPagamento ? AppTheme.errorRed : AppTheme.successGreen,
            ),
          ),
        ],
      ),
    );
  }
}