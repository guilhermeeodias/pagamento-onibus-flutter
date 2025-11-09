import 'package:flutter/material.dart';
import 'package:demo_onibus/main.dart';

class TelaHistoricoCompleto extends StatelessWidget {
  final List<Map<String, dynamic>> historico;

  const TelaHistoricoCompleto({super.key, required this.historico});

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      body: SafeArea(
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
                    child: Text(
                      'Histórico Completo',
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                    child: IconButton(
                      icon: Icon(
                        isDark ? Icons.light_mode : Icons.dark_mode,
                        color: AppTheme.textSecondaryColor(context),
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        AppTheme.toggleTheme();
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            // Contador de transações
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark 
                      ? const Color(0xFF273449)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: isDark ? null : Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withAlpha(26),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.receipt_long,
                        color: AppTheme.primaryBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total de Transações',
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor(context),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${historico.length} registros',
                          style: TextStyle(
                            color: AppTheme.textColor(context),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Lista de histórico
            Expanded(
              child: historico.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: AppTheme.textSecondaryColor(context).withAlpha(128),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhuma transação ainda',
                            style: TextStyle(
                              color: AppTheme.textSecondaryColor(context),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: historico.length,
                      itemBuilder: (context, index) {
                        final item = historico[index];
                        return _buildHistoricoItem(context, item, isDark);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoricoItem(BuildContext context, Map<String, dynamic> item, bool isDark) {
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