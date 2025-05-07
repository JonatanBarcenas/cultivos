import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:usb_serial/usb_serial.dart';
import 'dart:io';

import '../main.dart';

class UsbDiagnosticScreen extends StatefulWidget {
  const UsbDiagnosticScreen({super.key});

  @override
  State<UsbDiagnosticScreen> createState() => _UsbDiagnosticScreenState();
}

class _UsbDiagnosticScreenState extends State<UsbDiagnosticScreen> {
  List<dynamic> _devices = [];
  bool _isRefreshing = false;
  String _diagnosticMessage = '';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _refreshDevices();
  }

  Future<void> _refreshDevices() async {
    setState(() {
      _isRefreshing = true;
      _diagnosticMessage = '';
      _hasError = false;
    });

    try {
      final provider = Provider.of<DashboardProvider>(context, listen: false);
      await provider.refreshDevices();
      
      setState(() {
        _devices = provider.serialService.devices;
        _isRefreshing = false;
      });

      if (_devices.isEmpty) {
        setState(() {
          _diagnosticMessage = 'No se encontraron dispositivos USB. Verifica la conexión y los drivers.';
          _hasError = true;
        });
      }
    } catch (e) {
      setState(() {
        _diagnosticMessage = 'Error al listar dispositivos USB: $e';
        _hasError = true;
        _isRefreshing = false;
      });
    }
  }

  String _getDeviceType(dynamic device) {
    if (Platform.isWindows) {
      // Para Windows, el dispositivo es un Map con información del puerto serie
      final isEsp32 = device['isEsp32'] as bool? ?? false;
      final description = device['description'] as String? ?? 'Desconocido';
      final manufacturer = device['manufacturer'] as String? ?? '';
      
      if (isEsp32) {
        // Intentar determinar el tipo específico de ESP32
        if (description.toLowerCase().contains('cp210') || 
            manufacturer.toLowerCase().contains('silicon labs')) {
          return 'ESP32 (CP210x)';
        } else if (description.toLowerCase().contains('ch340') || 
                  description.toLowerCase().contains('ch341')) {
          return 'ESP32 (CH340/CH341)';
        } else if (description.toLowerCase().contains('ftdi')) {
          return 'ESP32 (FTDI)';
        } else {
          return 'ESP32';
        }
      } else {
        return 'Otro dispositivo';
      }
    } else {
      // Para Android, el dispositivo es un UsbDevice
      final usbDevice = device as UsbDevice;
      final vid = usbDevice.vid?.toRadixString(16).toUpperCase() ?? 'unknown';
      final pid = usbDevice.pid?.toRadixString(16).toUpperCase() ?? 'unknown';
      
      // ESP32 identifiers
      final esp32Identifiers = {
        'CP210x': ['10C4', 'EA60'], // Silicon Labs CP210x
        'CH340': ['1A86', '7523'],  // WCH CH340
        'CH341': ['1A86', '5523'],  // WCH CH341
        'FTDI': ['0403', '6001'],   // FTDI FT232R
      };
      
      for (final entry in esp32Identifiers.entries) {
        if (entry.value[0] == vid && entry.value[1] == pid) {
          return 'ESP32 (${entry.key})';
        }
      }
      
      return 'Otro dispositivo';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.primaryContainer,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        title: Text(
          'Diagnóstico USB',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshDevices,
            tooltip: 'Actualizar dispositivos',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Diagnostic message
            if (_diagnosticMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: _hasError ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _hasError ? Colors.red : Colors.green,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _hasError ? Icons.error : Icons.info,
                      color: _hasError ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _diagnosticMessage,
                        style: TextStyle(
                          color: _hasError ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Device list
            Text(
              'Dispositivos USB detectados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            
            const SizedBox(height: 16),
            
            if (_isRefreshing)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (_devices.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.usb_off,
                      size: 64,
                      color: Colors.grey.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No se encontraron dispositivos USB',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Conecta un dispositivo y presiona el botón de actualizar',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _devices.length,
                itemBuilder: (context, index) {
                  final device = _devices[index];
                  final deviceType = _getDeviceType(device);
                  final isEsp32 = deviceType.startsWith('ESP32');
                  
                  // Obtener información del dispositivo según la plataforma
                  String deviceInfo = '';
                  if (Platform.isWindows) {
                    final portName = device['portName'] as String? ?? 'Desconocido';
                    final description = device['description'] as String? ?? 'Desconocido';
                    deviceInfo = 'Puerto: $portName\nDescripción: $description';
                  } else {
                    final usbDevice = device as UsbDevice;
                    final vid = usbDevice.vid?.toRadixString(16).toUpperCase() ?? 'unknown';
                    final pid = usbDevice.pid?.toRadixString(16).toUpperCase() ?? 'unknown';
                    deviceInfo = 'VID: $vid, PID: $pid';
                  }
                  
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isEsp32 ? Colors.green : Colors.grey,
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isEsp32 ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.usb,
                          color: isEsp32 ? Colors.green : Colors.grey,
                        ),
                      ),
                      title: Text(
                        deviceType,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(deviceInfo),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          final provider = Provider.of<DashboardProvider>(context, listen: false);
                          final result = await provider.connectToDevice(device);
                          
                          if (result) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Dispositivo conectado exitosamente'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Error al conectar con el dispositivo'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isEsp32 ? Colors.green : Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Conectar'),
                      ),
                    ),
                  );
                },
              ),
            
            const SizedBox(height: 24),
            
            // Troubleshooting tips
            Text(
              'Solución de problemas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            
            const SizedBox(height: 16),
            
            _buildTroubleshootingTip(
              'Verifica la conexión física',
              'Asegúrate de que el cable USB esté bien conectado y que sea un cable de datos (no solo de carga).',
              Icons.cable,
            ),
            
            _buildTroubleshootingTip(
              'Instala los drivers correctos',
              'Para ESP32 con chip CP210x: Instala los drivers de Silicon Labs.\nPara ESP32 con chip CH340/CH341: Instala los drivers de WCH.',
              Icons.download,
            ),
            
            _buildTroubleshootingTip(
              'Verifica en el Administrador de dispositivos',
              'Abre el Administrador de dispositivos de Windows y busca en "Puertos (COM y LPT)" si aparece tu dispositivo.',
              Icons.devices,
            ),
            
            _buildTroubleshootingTip(
              'Reinicia el dispositivo',
              'Desconecta y vuelve a conectar la ESP32. A veces es necesario reiniciar el dispositivo.',
              Icons.refresh,
            ),
            
            _buildTroubleshootingTip(
              'Prueba otro puerto USB',
              'Algunos puertos USB pueden tener problemas. Prueba con otro puerto USB de tu computadora.',
              Icons.usb,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTroubleshootingTip(String title, String description, IconData icon) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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