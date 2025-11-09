import 'package:flutter/material.dart';
import 'package:demo_onibus/tela_passageiro.dart';
import 'package:demo_onibus/tela_motorista.dart';
import 'package:demo_onibus/tela_creditos.dart';
import 'package:demo_onibus/tela_senha.dart';
import 'package:demo_onibus/main.dart';
// Importe o StorageHelper para poder fazer logout
import 'package:demo_onibus/transaction_list.dart'; 

class TelaDeEscolha extends StatefulWidget {
  final String nomeUsuario;

  const TelaDeEscolha({super.key, required this.nomeUsuario});

  @override
  State<TelaDeEscolha> createState() => _TelaDeEscolhaState();
}

class _TelaDeEscolhaState extends State<TelaDeEscolha> with SingleTickerProviderStateMixin {
  int _contadorTaps = 0;
  DateTime? _ultimoTap;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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
    final isDark = AppTheme.isDark(context);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Header com ícone de configurações e tema
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
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
                
                const SizedBox(height: 40),
                
                // Ícone de pessoas
                GestureDetector(
                  onTap: _contarTaps,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.people_outline,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                Text(
                  "Escolha seu modo",
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Como você quer usar o app hoje?",
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor(context),
                    fontSize: 15,
                  ),
                ),
                
                const Spacer(),
                
                // Botão Passageiro
                _buildModeButton(
                  icon: Icons.person_outline,
                  title: 'Sou PASSAGEIRO',
                  subtitle: 'Pagar passagens e ver saldo',
                  color: AppTheme.primaryBlue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TelaPassageiro(
                          nomeUsuario: widget.nomeUsuario,
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Botão Motorista
                _buildModeButton(
                  icon: Icons.shield_outlined,
                  title: 'Sou MOTORISTA',
                  subtitle: 'Validar pagamentos',
                  color: isDark ? const Color(0xFF273449) : const Color(0xFFE2E8F0),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TelaMotorista()),
                    );
                  },
                ),
                
                const SizedBox(height: 30),
                
                // Link Sair (COM A CORREÇÃO)
                TextButton(
                  onPressed: () async {
                    // 1. Chamar o logout
                    await StorageHelper.logout(); 

                    // 2. Verificar se o contexto é válido
                    if (!context.mounted) return; 

                    // 3. Navegar para a tela de login
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const TelaSenha()),
                      (route) => false,
                    );
                  },
                  child: Text(
                    "Sair (Login)",
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor(context),
                      fontSize: 14,
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = AppTheme.isDark(context);
    final isBlueButton = color == AppTheme.primaryBlue;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: !isDark && !isBlueButton ? Border.all(
            color: const Color(0xFFCBD5E1),
            width: 1,
          ) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isBlueButton 
                    ? Colors.white.withAlpha(26)
                    : (isDark ? Colors.white.withAlpha(26) : AppTheme.primaryBlue.withAlpha(26)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isBlueButton 
                    ? Colors.white
                    : (isDark ? Colors.white : AppTheme.primaryBlue),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isBlueButton 
                          ? Colors.white
                          : (isDark ? Colors.white : AppTheme.lightText),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isBlueButton
                          ? Colors.white.withAlpha(179)
                          : (isDark ? Colors.white.withAlpha(179) : AppTheme.lightTextSecondary),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}