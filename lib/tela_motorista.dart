import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ble_peripheral/ble_peripheral.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:demo_onibus/main.dart';

const String serviceUuid = "0000180D-0000-1000-8000-00805F9B34FB";
const String pingPagamentoUuid = "0000180A-0000-1000-8000-00805F9B34FB";

class TelaMotorista extends StatefulWidget {
  const TelaMotorista({super.key});

  @override
  State<TelaMotorista> createState() => _TelaMotoristaState();
}

class _TelaMotoristaState extends State<TelaMotorista>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  
  String statusTexto = "Iniciando validador...";
  Color statusCor = Colors.grey;
  bool tentandoIniciar = false;
  bool bleAtivo = false;

  List<Map<String, dynamic>> pagamentosRecebidos = [];
  StreamSubscription? _scanResultsSubscription;
  StreamSubscription? _adapterStateSubscription; // <-- ADICIONADO
  
  // A CHAVE (String) agora é o Device ID, não o nome
  final Map<String, DateTime> _pagamentosProcessados = {}; 
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // MUDANÇA: Agora chamamos o listener primeiro
        _setupBleListeners();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _pararBLE();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !bleAtivo) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          // MUDANÇA: Usamos o listener
          _setupBleListeners();
        }
      });
    }
  }

  Future<void> _pararBLE() async {
    _adapterStateSubscription?.cancel(); // <-- ADICIONADO
    _scanResultsSubscription?.cancel();
    try {
      if (bleAtivo) {
        await BlePeripheral.stopAdvertising();
        await FlutterBluePlus.stopScan();
      }
    } catch (e) {
      print("Erro ao parar BLE: $e");
    }
    bleAtivo = false;
  }

  // --- NOVA FUNÇÃO ---
  // Esta função ouve o estado do Bluetooth e reage
  Future<void> _setupBleListeners() async {
    if (tentandoIniciar) return; // Já estamos tentando
    tentandoIniciar = true;

    if (!mounted) return;
    setState(() {
      statusTexto = "Verificando permissões...";
      statusCor = Colors.orange;
    });

    final statuses = await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
    ].request();

    if (!mounted) {
      tentandoIniciar = false;
      return;
    }

    if (!statuses.values.every((status) => status.isGranted)) {
      setState(() {
        statusTexto = "Permissões Necessárias\n\n• Bluetooth\n• Localização";
        statusCor = Colors.red;
      });
      tentandoIniciar = false;
      return;
    }
    
    tentandoIniciar = false; // Verificação de permissão concluída

    // Agora, ouça o estado do Bluetooth
    _adapterStateSubscription?.cancel(); // Cancela qualquer listener antigo
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      if (!mounted) return;
      if (state == BluetoothAdapterState.on) {
        if (!bleAtivo) { // Só inicie se não estiver ativo
           _iniciarValidadorEOuvinte();
        }
      } else {
        // Bluetooth foi desligado
        if (bleAtivo) { // Se estávamos ativos, pare tudo
           _pararBLE();
        }
        setState(() {
          statusTexto = "Bluetooth desligado\n\nPor favor, ative o Bluetooth";
          statusCor = Colors.orange;
          bleAtivo = false; // Garante que o estado seja 'off'
        });
      }
    });
  }

  // --- FUNÇÃO MODIFICADA ---
  // Esta é a sua antiga 'iniciarValidadorEOuvinte', mas sem as permissões
  // Ela assume que o Bluetooth JÁ ESTÁ LIGADO
  Future<void> _iniciarValidadorEOuvinte() async {
    if (bleAtivo) return; // Já está ativo
    
    try {
      if (!mounted) return;
      setState(() {
        statusTexto = "Iniciando Validador";
        statusCor = Colors.blue;
      });

      // Garantir que o estado é 'on'
      var estadoBle = await FlutterBluePlus.adapterState.first;
      if (estadoBle != BluetoothAdapterState.on) {
         throw Exception("BLUETOOTH_NOT_ENABLED");
      }

      await BlePeripheral.initialize();
      await BlePeripheral.clearServices();
      await BlePeripheral.addService(
        BleService(
          uuid: serviceUuid,
          primary: true,
          characteristics: [],
        ),
      );

      await BlePeripheral.startAdvertising(
        services: [serviceUuid], 
        localName: "ValidadorOnibus",
      );

      // --- CORREÇÃO DE DUPLICIDADE APLICADA AQUI ---
      _scanResultsSubscription = FlutterBluePlus.onScanResults.listen(
        (results) {
          if (!mounted) return;
          for (var r in results) {
            if (r.advertisementData.serviceUuids.contains(Guid(pingPagamentoUuid))) {
              
              String nomePassageiro = r.advertisementData.advName;
              String deviceId = r.device.remoteId.str; // <-- FIX 1: Usar ID do Dispositivo

              // FIX 2: Ignorar se o nome for o do próprio validador
              if (nomePassageiro == "ValidadorOnibus") {
                continue; 
              }

              if (nomePassageiro.isEmpty) {
                nomePassageiro = "Passageiro";
              }

              final agora = DateTime.now();
              // FIX 3: Usar deviceId como chave no mapa
              final ultimoProcessamento = _pagamentosProcessados[deviceId]; 
              
              if (ultimoProcessamento != null && 
                  agora.difference(ultimoProcessamento).inSeconds < 3) {
                // Este DISPOSITIVO específico já pagou nos últimos 3s
                continue;
              }

              // FIX 4: Salvar o processamento usando o deviceId
              _pagamentosProcessados[deviceId] = agora; 
              
              if (mounted) {
                setState(() {
                  pagamentosRecebidos.insert(0, {
                    'valor': 2.0,
                    'nomeUsuario': nomePassageiro,
                    'dataHora': DateTime.now(),
                  });
                  if (pagamentosRecebidos.length > 10) {
                    pagamentosRecebidos.removeLast();
                  }
                });
              }
            }
          }
        },
        onError: (e) {
          print("Erro no Radar de Pagamento: $e");
        },
      );

      await FlutterBluePlus.startScan(
        timeout: null,
        androidScanMode: AndroidScanMode.lowLatency,
        continuousUpdates: true, 
        removeIfGone: const Duration(seconds: 2),
      );

      if (!mounted) return;
      bleAtivo = true;
      setState(() {
        statusTexto = "Validador Ativo\n\nAguardando pagamentos...";
        statusCor = Colors.green;
      });

    } catch (e) {
      if (!mounted) return;
      await _pararBLE(); // Pare tudo se der erro
      
      String erro = e.toString();
      bleAtivo = false;

      if (erro.contains('BLUETOOTH_NOT_ENABLED') || erro.contains('disabled')) {
        setState(() {
          statusTexto = "Bluetooth desligado\n\nPor favor, ative o Bluetooth";
          statusCor = Colors.orange;
        });
      } else {
        setState(() {
          statusTexto = "ERRO ao ligar o validador:\n$e";
          statusCor = Colors.red;
        });
      }
    }
  }


  String _formatarHora(DateTime data) {
    return '${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}:${data.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // ... (O RESTO DO SEU MÉTODO build CONTINUA IGUAL)
    // ... (NENHUMA MUDANÇA DAQUI PARA BAIXO)
    final isDark = AppTheme.isDark(context);
    final bool isActive = statusCor == Colors.green;
    
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _pararBLE();
        }
      },
      child: Scaffold(
        backgroundColor: isActive 
            ? (isDark ? const Color(0xFF064e3b) : const Color(0xFFd1fae5))
            : AppTheme.backgroundColor(context),
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
                        color: isActive
                            ? (isDark ? const Color(0xFF065f46) : Colors.white)
                            : AppTheme.cardColor(context),
                        borderRadius: BorderRadius.circular(10),
                        border: !isDark && !isActive ? Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1,
                        ) : null,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: isActive
                              ? (isDark ? Colors.white : const Color(0xFF065f46))
                              : AppTheme.textColor(context),
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Modo Motorista',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isActive
                            ? (isDark ? const Color(0xFF065f46) : Colors.white)
                            : AppTheme.cardColor(context),
                        borderRadius: BorderRadius.circular(10),
                        border: !isDark && !isActive ? Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1,
                        ) : null,
                      ),
                      child: Icon(
                        Icons.settings_outlined,
                        color: isActive
                            ? (isDark ? const Color(0xFF6ee7b7) : const Color(0xFF059669))
                            : AppTheme.textSecondaryColor(context),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isActive
                            ? (isDark ? const Color(0xFF065f46) : Colors.white)
                            : AppTheme.cardColor(context),
                        borderRadius: BorderRadius.circular(10),
                        border: !isDark && !isActive ? Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1,
                        ) : null,
                      ),
                      child: IconButton(
                        icon: Icon(
                          isDark ? Icons.light_mode : Icons.dark_mode,
                          color: isActive
                              ? (isDark ? const Color(0xFF6ee7b7) : const Color(0xFF059669))
                              : AppTheme.textSecondaryColor(context),
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
              
              // Status do validador
              Expanded(
                flex: statusCor == Colors.green ? 1 : 2,
                child: Center(
                  child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (statusCor == Colors.green)
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isDark
                                          ? [const Color(0xFF10b981), const Color(0xFF059669)]
                                          : [const Color(0xFF34d399), const Color(0xFF10b981)],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF10b981).withAlpha(102),
                                        blurRadius: 30,
                                        spreadRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.shield_rounded,
                                    size: 60,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                          )
                        else if (statusCor == Colors.blue || statusCor == Colors.orange)
                          const SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryBlue,
                              strokeWidth: 4,
                            ),
                          )
                        else
                          Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              color: AppTheme.errorRed,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.error_outline,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            statusTexto,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: isActive
                                  ? (isDark ? Colors.white : const Color(0xFF065f46))
                                  : AppTheme.textColor(context),
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ),
                ),
              ),
              
              // Lista de pagamentos
              if (statusCor == Colors.green)
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark 
                          ? const Color(0xFF052e24)
                          : const Color(0xFFa7f3d0),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isDark 
                                      ? const Color(0xFF065f46)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.receipt_long_outlined,
                                  color: isDark 
                                      ? const Color(0xFF6ee7b7)
                                      : const Color(0xFF059669),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Pagamentos Recebidos',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark 
                                      ? Colors.white
                                      : const Color(0xFF065f46),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: pagamentosRecebidos.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.hourglass_empty,
                                          size: 48,
                                          color: isDark 
                                              ? const Color(0xFF059669)
                                              : const Color(0xFF10b981),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Nenhum pagamento ainda',
                                          style: TextStyle(
                                            color: isDark 
                                                ? const Color(0xFF6ee7b7)
                                                : const Color(0xFF047857),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.only(
                                    left: 16,
                                    right: 16,
                                    bottom: 16,
                                  ),
                                  itemCount: pagamentosRecebidos.length,
                                  itemBuilder: (context, index) {
                                    final pagamento = pagamentosRecebidos[index];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isDark 
                                            ? const Color(0xFF065f46)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: isDark
                                                    ? [const Color(0xFF10b981), const Color(0xFF059669)]
                                                    : [const Color(0xFF34d399), const Color(0xFF10b981)],
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  pagamento['nomeUsuario'] ?? 'Usuário',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 15,
                                                    color: isDark 
                                                        ? Colors.white
                                                        : const Color(0xFF065f46),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  _formatarHora(pagamento['dataHora']),
                                                  style: TextStyle(
                                                    color: isDark 
                                                        ? const Color(0xFF6ee7b7)
                                                        : const Color(0xFF059669),
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '+ R\$ ${pagamento['valor'].toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: isDark 
                                                  ? const Color(0xFF6ee7b7)
                                                  : const Color(0xFF047857),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
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
}