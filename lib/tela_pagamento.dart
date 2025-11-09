import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart'; 
import 'package:ble_peripheral/ble_peripheral.dart'; 
import 'package:permission_handler/permission_handler.dart';
import 'package:demo_onibus/tela_sucesso_pagamento.dart';
import 'package:demo_onibus/main.dart';

const String serviceUuid = "0000180D-0000-1000-8000-00805F9B34FB";
const String pingPagamentoUuid = "0000180A-0000-1000-8000-00805F9B34FB";

class TelaPagamento extends StatefulWidget {
  final double saldoAtual;
  final double precoPassagem;
  final String nomeUsuario;

  const TelaPagamento({
    super.key,
    required this.saldoAtual,
    required this.precoPassagem,
    required this.nomeUsuario,
  });

  @override
  State<TelaPagamento> createState() => _TelaPagamentoState();
}

// --- MUDANÇA AQUI ---
class _TelaPagamentoState extends State<TelaPagamento>
    with TickerProviderStateMixin, WidgetsBindingObserver { // <-- ADICIONADO
  
  String statusTexto = "Iniciando scanner...";
  Color statusCor = Colors.orange;
  bool podePagar = false;
  StreamSubscription? _adapterStateSubscription;
  StreamSubscription? _scanResultsSubscription;
  bool estamosEscaneando = false;
  bool pedindoParaLigarBluetooth = false;

  final int limiteRssi = -70;

  DateTime? _ultimaDeteccao;

  bool _estaPagando = false;
  
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // <-- ADICIONADO

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    
    _waveAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    pedirPermissoes();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // <-- ADICIONADO
    _waveController.dispose();
    _pulseController.dispose();
    _adapterStateSubscription?.cancel();
    _scanResultsSubscription?.cancel();
    FlutterBluePlus.stopScan();
    BlePeripheral.stopAdvertising();
    super.dispose();
  }

  // --- NOVA FUNÇÃO ADICIONADA ---
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !estamosEscaneando && !_estaPagando) {
      // Se o app foi resumido e não estamos escaneando (ou no meio de um pagto),
      // é provável que o OS parou o scan. Vamos reiniciar.
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          pedirPermissoes(); // Reinicia o fluxo de permissão e scan
        }
      });
    }
  }


  Future<void> pedirPermissoes() async {
    var statuses = await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise, 
    ].request();

    if (statuses.values.every((status) => status.isGranted)) {
      if (!mounted) return;
      ouvirEstadoDoBluetooth();
    } else {
      if (!mounted) return;
      setState(() {
        statusTexto = "ERRO: Permissões negadas.";
        statusCor = Colors.red;
      });
    }
  }

  void ouvirEstadoDoBluetooth() async {
    var estadoAtual = await FlutterBluePlus.adapterState.first;
    if (estadoAtual == BluetoothAdapterState.off && !pedindoParaLigarBluetooth) {
      pedindoParaLigarBluetooth = true;
      if (!mounted) return;
      setState(() {
        statusTexto = "Ligando Bluetooth...";
        statusCor = Colors.orange;
      });
      try {
        if (Theme.of(context).platform == TargetPlatform.android) {
          await FlutterBluePlus.turnOn();
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          statusTexto = "Por favor, ligue o Bluetooth manualmente";
          statusCor = Colors.red;
        });
      }
      pedindoParaLigarBluetooth = false;
    }
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      if (!mounted) return;
      if (state == BluetoothAdapterState.on) {
        iniciarScannerDeProximidade();
      } else {
        setState(() {
          statusTexto = "Bluetooth desligado.\nPor favor, ligue o Bluetooth.";
          statusCor = Colors.red;
          podePagar = false;
        });
        FlutterBluePlus.stopScan();
        estamosEscaneando = false;
      }
    });
  }
  
  void iniciarScannerDeProximidade() async {
    if (estamosEscaneando) return;
    if (!mounted) return;
    setState(() {
      statusTexto = "Procurando ônibus...";
      statusCor = Colors.orange;
    });
    _scanResultsSubscription = FlutterBluePlus.onScanResults.listen(
      (results) {
        if (!mounted || _estaPagando) return; 
        bool encontrado = false;
        for (var r in results) {
          if (r.advertisementData.serviceUuids
              .contains(Guid(serviceUuid))) {
            encontrado = true;
            _ultimaDeteccao = DateTime.now();
            int rssi = r.rssi;
            if (rssi > limiteRssi) {
              setState(() {
                statusTexto = "ÔNIBUS ENCONTRADO!\nForça do sinal: $rssi";
                statusCor = Colors.green;
                podePagar = true;
              });
            } else {
              setState(() {
                statusTexto =
                    "Aproxime-se do validador...\nForça do sinal: $rssi";
                statusCor = Colors.orange;
                podePagar = false;
              });
            }
            break;
          }
        }
        if (!encontrado) {
          if (_ultimaDeteccao != null) {
            final diferenca = DateTime.now().difference(_ultimaDeteccao!);
            if (diferenca.inMilliseconds > 800) {
              setState(() {
                statusTexto = "Procurando ônibus...";
                statusCor = Colors.orange;
                podePagar = false;
              });
              _ultimaDeteccao = null;
            }
          } else {
            setState(() {
              statusTexto = "Procurando ônibus...";
              statusCor = Colors.orange;
              podePagar = false;
            });
          }
        }
      },
      onError: (e) {
        if (!mounted) return;
        setState(() {
          statusTexto = "ERRO ao escanear: $e";
          statusCor = Colors.red;
        });
      },
    );
    try {
      await FlutterBluePlus.startScan(
        timeout: null,
        androidScanMode: AndroidScanMode.lowLatency,
        removeIfGone: const Duration(milliseconds: 600),
        continuousUpdates: true,
        continuousDivisor: 1,
      );
      estamosEscaneando = true;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        statusTexto = "ERRO ao iniciar o scan: $e";
        statusCor = Colors.red;
      });
    }
  }

  Future<void> _anunciarPagamento() async {
    if (widget.saldoAtual < widget.precoPassagem) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text("Saldo Insuficiente!"),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() {
      _estaPagando = true; 
      statusTexto = "Enviando PING de pagamento...";
      statusCor = Colors.blue;
    });

    await FlutterBluePlus.stopScan();
    estamosEscaneando = false;
    _scanResultsSubscription?.cancel();

    try {
      await BlePeripheral.initialize();
      await BlePeripheral.clearServices();

      await BlePeripheral.addService(
        BleService(
          uuid: pingPagamentoUuid,
          primary: true,
          characteristics: [],
        ),
      );

      String nomeCurto = widget.nomeUsuario;
      if (nomeCurto.length > 15) {
        nomeCurto = nomeCurto.substring(0, 15);
      }

      await BlePeripheral.startAdvertising(
        services: [pingPagamentoUuid], 
        localName: nomeCurto,
      );

      await Future.delayed(const Duration(seconds: 1));

      await BlePeripheral.stopAdvertising();
      
      if (!mounted) return;
      
      double novoSaldo = widget.saldoAtual - widget.precoPassagem;
      _adapterStateSubscription?.cancel();

      final resultado = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TelaSucessoPagamento(
            valorPago: widget.precoPassagem,
            novoSaldo: novoSaldo,
          ),
        ),
      );

      if (mounted && resultado == true) {
        Navigator.pop(context, novoSaldo);
      }

    } catch (e) {
      if (!mounted) return;
      setState(() {
        statusTexto = "Falha no envio:\n${e.toString()}";
        statusCor = Colors.red;
        _estaPagando = false;
      });
      iniciarScannerDeProximidade();

    } finally {
      try {
        await BlePeripheral.stopAdvertising();
      } catch (_) {}
      
      if (mounted) {
        setState(() {
          _estaPagando = false; 
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (O RESTO DO SEU MÉTODO build CONTINUA IGUAL)
    // ... (NENHUMA MUDANÇA DAQUI PARA BAIXO)
    final isDark = AppTheme.isDark(context);
    final bool isSuccess = podePagar && !_estaPagando;
    
    return Scaffold(
      backgroundColor: isSuccess 
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
                      color: isSuccess
                          ? (isDark ? const Color(0xFF065f46) : Colors.white)
                          : AppTheme.cardColor(context),
                      borderRadius: BorderRadius.circular(10),
                      border: !isDark && !isSuccess ? Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ) : null,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.close,
                        color: isSuccess
                            ? (isDark ? Colors.white : const Color(0xFF065f46))
                            : AppTheme.textColor(context),
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Pagar Passagem',
                        style: TextStyle(
                          color: isSuccess
                              ? (isDark ? Colors.white : const Color(0xFF065f46))
                              : AppTheme.textColor(context),
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
                      color: isSuccess
                          ? (isDark ? const Color(0xFF065f46) : Colors.white)
                          : AppTheme.cardColor(context),
                      borderRadius: BorderRadius.circular(10),
                      border: !isDark && !isSuccess ? Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ) : null,
                    ),
                    child: Icon(
                      Icons.settings_outlined,
                      color: isSuccess
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
                      color: isSuccess
                          ? (isDark ? const Color(0xFF065f46) : Colors.white)
                          : AppTheme.cardColor(context),
                      borderRadius: BorderRadius.circular(10),
                      border: !isDark && !isSuccess ? Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ) : null,
                    ),
                    child: IconButton(
                      icon: Icon(
                        isDark ? Icons.light_mode : Icons.dark_mode,
                        color: isSuccess
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
            
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (podePagar && !_estaPagando)
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: isDark
                                        ? [const Color(0xFF10b981), const Color(0xFF059669)]
                                        : [const Color(0xFF34d399), const Color(0xFF10b981)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF10b981).withAlpha(102),
                                      blurRadius: 30,
                                      spreadRadius: 10,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.check_circle_rounded,
                                  size: 100,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        )
                      else if (_estaPagando)
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor(context),
                            shape: BoxShape.circle,
                            border: !isDark ? Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1,
                            ) : null,
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 60,
                              height: 60,
                              child: CircularProgressIndicator(
                                color: AppTheme.primaryBlue,
                                strokeWidth: 5,
                              ),
                            ),
                          ),
                        )
                      else
                        AnimatedBuilder(
                          animation: _waveAnimation,
                          builder: (context, child) {
                            return Container(
                              width: 160 * _waveAnimation.value,
                              height: 160 * _waveAnimation.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.primaryBlue.withAlpha(102),
                                  width: 2,
                                ),
                              ),
                            );
                          },
                        ),
                      
                      const SizedBox(height: 40),
                      
                      Text(
                        statusTexto,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          color: isSuccess
                              ? (isDark ? Colors.white : const Color(0xFF065f46))
                              : AppTheme.textColor(context),
                          fontWeight: isSuccess ? FontWeight.bold : FontWeight.normal,
                          height: 1.4,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        'Aproxime seu celular do validador para pagar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSuccess
                              ? (isDark ? const Color(0xFF6ee7b7) : const Color(0xFF059669))
                              : AppTheme.textSecondaryColor(context),
                        ),
                      ),
                      
                      const SizedBox(height: 60),
                      
                      if (podePagar && !_estaPagando)
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark 
                                  ? const Color(0xFF10b981)
                                  : const Color(0xFF059669),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            onPressed: _anunciarPagamento,
                            child: const Text(
                              '(Simular Encontro)',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}