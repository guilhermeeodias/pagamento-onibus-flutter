import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageHelper {
  static const String _historicoKey = 'historico_transacoes';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _nomeUsuarioKey = 'nome_usuario';
  static const int maxHistorico = 30;

  // Salvar histórico
  static Future<void> salvarHistorico(List<Map<String, dynamic>> historico) async {
    final prefs = await SharedPreferences.getInstance();
    final historicoLimitado = historico.take(maxHistorico).toList();
    final historicoJson = historicoLimitado.map((item) {
      return {
        'tipo': item['tipo'],
        'valor': item['valor'],
        'data': item['data'],
      };
    }).toList();
    await prefs.setString(_historicoKey, jsonEncode(historicoJson));
  }

  // Carregar histórico
  static Future<List<Map<String, dynamic>>> carregarHistorico() async {
    final prefs = await SharedPreferences.getInstance();
    final historicoString = prefs.getString(_historicoKey);

    // <-- CORREÇÃO 4: Garantir que a lista vazia tenha o tipo certo
    if (historicoString == null) return <Map<String, dynamic>>[];
    
    final List<dynamic> historicoJson = jsonDecode(historicoString);

    // <-- CORREÇÃO 5: Forçar o tipo do mapa ao carregar do JSON
    return historicoJson.map((item) => {
      'tipo': item['tipo'] as String,
      'valor': (item['valor'] as num).toDouble(),
      'data': item['data'] as String,
    } as Map<String, dynamic>).toList(); // <-- "as Map<String, dynamic>" AQUI
  }

  // Limpar histórico (ao deslogar)
  static Future<void> limparHistorico() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historicoKey);
  }

  // Salvar estado de login
  static Future<void> salvarLogin(String nomeUsuario) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_nomeUsuarioKey, nomeUsuario);
  }

  // Verificar se está logado
  static Future<bool> estaLogado() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Obter nome do usuário logado
  static Future<String?> obterNomeUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nomeUsuarioKey);
  }

  // Fazer logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_nomeUsuarioKey);
    await limparHistorico();
  }
}