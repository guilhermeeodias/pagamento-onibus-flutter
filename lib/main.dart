import 'package:demo_onibus/tela_senha.dart';
import 'package:demo_onibus/tela_escolha.dart';
import 'package:demo_onibus/transaction_list.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);
  bool _isLoading = true;
  bool _isLoggedIn = false;
  String? _nomeUsuario;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await StorageHelper.estaLogado();
    final nomeUsuario = await StorageHelper.obterNomeUsuario();
    
    setState(() {
      _isLoggedIn = isLoggedIn;
      _nomeUsuario = nomeUsuario;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        if (_isLoading) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: const Color(0xFF1a2332),
              body: Center(
                child: CircularProgressIndicator(
                  color: Colors.blue[400],
                ),
              ),
            ),
          );
        }
        
        return MaterialApp(
          title: 'Demo Onibus',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
            brightness: Brightness.dark,
          ),
          themeMode: currentMode,
          home: _isLoggedIn && _nomeUsuario != null
              ? TelaDeEscolha(nomeUsuario: _nomeUsuario!)
              : const TelaSenha(),
          debugShowCheckedModeBanner: false, 
        );
      },
    );
  }
}

class AppTheme {
  static ValueNotifier<ThemeMode> get themeNotifier => _MyAppState.themeNotifier;
  
  static bool isDark(BuildContext context) {
    final mode = themeNotifier.value;
    if (mode == ThemeMode.system) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    return mode == ThemeMode.dark;
  }
  
  static void toggleTheme() {
    themeNotifier.value = themeNotifier.value == ThemeMode.dark 
        ? ThemeMode.light 
        : ThemeMode.dark;
  }
  
  // Cores para modo escuro
  static const darkBackground = Color(0xFF1a2332);
  static const darkCard = Color(0xFF273449);
  static const darkCardSecondary = Color(0xFF1f2937);
  static const darkText = Colors.white;
  static const darkTextSecondary = Color(0xFF94a3b8);
  
  // Cores para modo claro
  static const lightBackground = Color(0xFFF8FAFC);
  static const lightCard = Colors.white;
  static const lightCardSecondary = Color(0xFFF1F5F9);
  static const lightText = Color(0xFF1E293B);
  static const lightTextSecondary = Color(0xFF64748B);
  
  // Cores que não mudam
  static const primaryBlue = Color(0xFF3b82f6);
  static const primaryBlueLight = Color(0xFF2563eb);
  static const successGreen = Color(0xFF22c55e);
  static const errorRed = Color(0xFFef4444);
  
  static Color backgroundColor(BuildContext context) {
    return isDark(context) ? darkBackground : lightBackground;
  }
  
  static Color cardColor(BuildContext context) {
    return isDark(context) ? darkCard : lightCard;
  }
  
  static Color cardSecondaryColor(BuildContext context) {
    return isDark(context) ? darkCardSecondary : lightCardSecondary;
  }
  
  static Color textColor(BuildContext context) {
    return isDark(context) ? darkText : lightText;
  }
  
  static Color textSecondaryColor(BuildContext context) {
    return isDark(context) ? darkTextSecondary : lightTextSecondary;
  }
}