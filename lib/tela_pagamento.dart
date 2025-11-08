import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart'; 
import 'package:ble_peripheral/ble_peripheral.dart'; 
import 'package:permission_handler/permission_handler.dart';
import 'package:demo_onibus/tela_sucesso_pagamento.dart';

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

class _TelaPagamentoState extends State<TelaPagamento> {
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

  @override
  void initState() {
    super.initState();
    pedirPermissoes();
  }

  @override
  void dispose() {
    _adapterStateSubscription?.cancel();
    _scanResultsSubscription?.cancel();
    FlutterBluePlus.stopScan();
    BlePeripheral.stopAdvertising();
    super.dispose();
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
        const SnackBar(
          content: Text("Saldo Insuficiente!"),
          backgroundColor: Colors.red,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagando Passagem...'),
        backgroundColor: statusCor,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              statusTexto,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: podePagar && !_estaPagando ? 1.0 : 0.0,
              child: SizedBox(
                width: 250,
                height: 80,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: podePagar && !_estaPagando ? _anunciarPagamento : null,
                  child: Text(
                    'Confirmar Pagamento\nR\$ ${widget.precoPassagem.toStringAsFixed(2)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            if (_estaPagando)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    CircularProgressIndicator(
                      color: Colors.blue,
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Enviando PING...",
                      style: TextStyle(fontSize: 16, color: Colors.blue),
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