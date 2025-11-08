import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ble_peripheral/ble_peripheral.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

const String serviceUuid = "0000180D-0000-1000-8000-00805F9B34FB";
const String pingPagamentoUuid = "0000180A-0000-1000-8000-00805F9B34FB";

class TelaMotorista extends StatefulWidget {
  const TelaMotorista({super.key});

  @override
  State<TelaMotorista> createState() => _TelaMotoristaState();
}

class _TelaMotoristaState extends State<TelaMotorista>
    with WidgetsBindingObserver {
  
  String statusTexto = "Iniciando validador...";
  Color statusCor = Colors.grey;
  bool tentandoIniciar = false;
  bool bleAtivo = false;

  List<Map<String, dynamic>> pagamentosRecebidos = [];
  StreamSubscription? _scanResultsSubscription;
  
  final Map<String, DateTime> _pagamentosProcessados = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        iniciarValidadorEOuvinte();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pararBLE();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !bleAtivo && !tentandoIniciar) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          iniciarValidadorEOuvinte();
        }
      });
    }
  }

  Future<void> _pararBLE() async {
    try {
      if (bleAtivo) {
        await BlePeripheral.stopAdvertising();
        await FlutterBluePlus.stopScan();
      }
    } catch (e) {
      print("Erro ao parar BLE: $e");
    }
    bleAtivo = false;
    _scanResultsSubscription?.cancel();
  }

  Future<void> iniciarValidadorEOuvinte() async {
    if (tentandoIniciar || bleAtivo) return;
    tentandoIniciar = true;

    try {
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

      if (!mounted) return;

      if (!statuses.values.every((status) => status.isGranted)) {
        setState(() {
          statusTexto = "⚠️ Permissões Necessárias\n\n• Bluetooth\n• Localização";
          statusCor = Colors.red;
        });
        tentandoIniciar = false;
        return;
      }

      setState(() {
        statusTexto = "Inicializando validador...";
        statusCor = Colors.blue;
      });

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

      var estadoBle = await FlutterBluePlus.adapterState.first;
      if (estadoBle != BluetoothAdapterState.on) {
         throw Exception("BLUETOOTH_NOT_ENABLED");
      }

      _scanResultsSubscription = FlutterBluePlus.onScanResults.listen(
        (results) {
          if (!mounted) return;
          for (var r in results) {
            if (r.advertisementData.serviceUuids.contains(Guid(pingPagamentoUuid))) {
              
              String nomePassageiro = r.advertisementData.advName;
              if (nomePassageiro.isEmpty) {
                nomePassageiro = "Passageiro";
              }

              final agora = DateTime.now();
              final ultimoProcessamento = _pagamentosProcessados[nomePassageiro];
              
              if (ultimoProcessamento != null && 
                  agora.difference(ultimoProcessamento).inSeconds < 3) {
                continue;
              }

              _pagamentosProcessados[nomePassageiro] = agora;
              
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
        statusTexto = "✅ Validador Ativo\n\nAguardando pagamentos...";
        statusCor = Colors.green;
      });

    } catch (e) {
      if (!mounted) return;
      await FlutterBluePlus.stopScan();
      String erro = e.toString();
      bleAtivo = false;

      if (erro.contains('BLUETOOTH_NOT_ENABLED') || erro.contains('disabled')) {
        setState(() {
          statusTexto = "🔵 Bluetooth desligado\n\nPor favor, ative o Bluetooth";
          statusCor = Colors.orange;
        });
        tentandoIniciar = false;
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && !bleAtivo) {
            iniciarValidadorEOuvinte();
          }
        });
      } else {
        setState(() {
          statusTexto = "ERRO ao ligar o validador:\n$e";
          statusCor = Colors.red;
        });
        tentandoIniciar = false;
      }
    }
  }

  String _formatarHora(DateTime data) {
    return '${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}:${data.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _pararBLE();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Modo Motorista'),
          backgroundColor: statusCor,
          foregroundColor: Colors.white,
        ),
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          color: statusCor,
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  flex: statusCor == Colors.green ? 2 : 3,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(30.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (statusCor == Colors.green)
                            const Icon(Icons.check_circle_outline,
                                size: 80, color: Colors.white),
                          if (statusCor == Colors.orange || statusCor == Colors.blue)
                            const SizedBox(
                              width: 60,
                              height: 60,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 6),
                            ),
                          if (statusCor == Colors.red)
                            const Icon(Icons.error_outline,
                                size: 80, color: Colors.white),
                          const SizedBox(height: 30),
                          Text(
                            statusTexto,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.5,
                            ),
                          ),
                          if (statusCor == Colors.red) ...[
                            const SizedBox(height: 30),
                            ElevatedButton.icon(
                              onPressed: () {
                                bleAtivo = false;
                                tentandoIniciar = false;
                                iniciarValidadorEOuvinte();
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Tentar Novamente'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 15),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                if (statusCor == Colors.green)
                  Expanded(
                    flex: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Pagamentos Recebidos',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Expanded(
                            child: pagamentosRecebidos.isEmpty
                                ? const Center(
                                    child: Text(
                                      'Nenhum pagamento ainda',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    itemCount: pagamentosRecebidos.length,
                                    itemBuilder: (context, index) {
                                      final pagamento = pagamentosRecebidos[index];
                                      return Card(
                                        color: Colors.white.withValues(alpha: 0.9),
                                        margin: const EdgeInsets.only(bottom: 12),
                                        child: ListTile(
                                          leading: const CircleAvatar(
                                            backgroundColor: Colors.green,
                                            child: Icon(Icons.check, color: Colors.white),
                                          ),
                                          title: Text(
                                            pagamento['nomeUsuario'] ?? 'Usuário',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          subtitle: Text(
                                            _formatarHora(pagamento['dataHora']),
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          trailing: Text(
                                            'R\$ ${pagamento['valor'].toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.green,
                                            ),
                                          ),
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
      ),
    );
  }
}