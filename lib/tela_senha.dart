import 'package:flutter/material.dart';
import 'package:demo_onibus/tela_escolha.dart';
import 'package:demo_onibus/transaction_list.dart';
import 'package:demo_onibus/main.dart';

class TelaSenha extends StatefulWidget {
  const TelaSenha({super.key});

  @override
  State<TelaSenha> createState() => _TelaSenhaState();
}

class _TelaSenhaState extends State<TelaSenha> with SingleTickerProviderStateMixin {
  final String _senhaCorreta = "123";
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _nomeController = TextEditingController();
  String _mensagemErro = "";
  bool _obscureText = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  void _validarSenha() async {
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

      // Salvar login
      await StorageHelper.salvarLogin(_nomeController.text.trim());

      if (!mounted) return;
      
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
    _animationController.dispose();
    _senhaController.dispose();
    _nomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(30.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Ícone do ônibus
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.directions_bus_rounded,
                          size: 45,
                          color: Colors.white,
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      Text(
                        "Bem-vindo(a)!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textColor(context),
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Acesse sua conta para continuar.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor(context),
                          fontSize: 15,
                        ),
                      ),
                      
                      const SizedBox(height: 50),
                      
                      // Campo Nome
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Seu nome",
                            style: TextStyle(
                              color: AppTheme.textSecondaryColor(context),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.cardColor(context),
                              borderRadius: BorderRadius.circular(12),
                              border: isDark ? null : Border.all(
                                color: const Color(0xFFE2E8F0),
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: _nomeController,
                              style: TextStyle(
                                color: AppTheme.textColor(context),
                                fontSize: 16,
                              ),
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                hintText: "Digite seu nome",
                                hintStyle: TextStyle(
                                  color: isDark ? const Color(0xFF64748b) : const Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Campo Senha
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Senha",
                            style: TextStyle(
                              color: AppTheme.textSecondaryColor(context),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.cardColor(context),
                              borderRadius: BorderRadius.circular(12),
                              border: isDark ? null : Border.all(
                                color: const Color(0xFFE2E8F0),
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: _senhaController,
                              obscureText: _obscureText,
                              style: TextStyle(
                                color: AppTheme.textColor(context),
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                hintText: "•••",
                                hintStyle: TextStyle(
                                  color: isDark ? const Color(0xFF64748b) : const Color(0xFF94A3B8),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: isDark ? const Color(0xFF64748b) : const Color(0xFF94A3B8),
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() { _obscureText = !_obscureText; });
                                  },
                                ),
                              ),
                              onSubmitted: (_) => _validarSenha(),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Botão Entrar
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primaryBlue, AppTheme.primaryBlueLight],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          onPressed: _validarSenha,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Entrar",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      
                      if (_mensagemErro.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.errorRed.withAlpha(26),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.errorRed.withAlpha(77),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _mensagemErro,
                                  style: const TextStyle(color: AppTheme.errorRed, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            
            // Botão de tema no canto superior direito
            Positioned(
              top: 16,
              right: 16,
              child: Container(
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
            ),
          ],
        ),
      ),
    );
  }
}