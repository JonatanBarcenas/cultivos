import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:usb_serial/transaction.dart';
import 'platform_service.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';

import '../models/sensor_data.dart';

class SerialService {
  // USB Serial port for Android
  UsbPort? _port;
  StreamSubscription<String>? _subscription;
  Transaction<String>? _transaction;
  
  // SerialPort for Windows
  SerialPort? _serialPort;
  SerialPortReader? _serialPortReader;
  StreamSubscription<Uint8List>? _winSubscription;
  
  // Buffer for storing incoming data fragments
  String _dataBuffer = '';
  
  final StreamController<SensorData> _dataStreamController = StreamController<SensorData>.broadcast();
  
  // Temporizador para datos simulados
  Timer? _mockDataTimer;
  
  // Expose stream of sensor data
  Stream<SensorData> get dataStream => _dataStreamController.stream;
  
  // Connection status
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  
  // Connection validation
  DateTime? _lastValidDataTime;
  Timer? _connectionValidationTimer;
  static const int _connectionTimeoutSeconds = 30; // Increased from 15 to 30 seconds
  int _consecutiveTimeoutsCount = 0;
  static const int _maxConsecutiveTimeouts = 999999; // Set to a very high number to effectively disable auto-disconnection
  
  // Available ports
  List<dynamic> _devices = [];
  List<dynamic> get devices => _devices;
  
  // ESP32 identifiers
  static const Map<String, List<String>> _esp32Identifiers = {
    'CP210x': ['10C4', 'EA60'], // Silicon Labs CP210x
    'CH340': ['1A86', '7523'],  // WCH CH340
    'CH341': ['1A86', '5523'],  // WCH CH341
    'FTDI': ['0403', '6001'],   // FTDI FT232R
    // Agregando más variantes comunes de CP210x
    'CP2102': ['10C4', 'EA60'], // Silicon Labs CP2102
    'CP2102N': ['10C4', 'EA60'], // Silicon Labs CP2102N
  };
  
  // Constructor
  SerialService() {
    _init();
    // Start connection validation timer
    _startConnectionValidationTimer();
  }
  
  // Initialize the service
  Future<void> _init() async {
    try {
      // Intentar inicializar comunicación USB
      await refreshDevices();
      
      // Automatically connect to the first available device if any
      if (_devices.isNotEmpty) {
        await connect(_devices[0]);
      } else {
        // Si no hay dispositivos o hay error, usar datos simulados
       
      }
    } catch (e) {
      debugPrint('Error durante la inicialización: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      
      
    }
  }
  
  
  // Refresh available devices
  Future<void> refreshDevices() async {
    try {
      if (Platform.isWindows) {
        // En Windows, usar libserialport
        try {
          _devices = [];
          final availablePorts = SerialPort.availablePorts;
          
          debugPrint('Puertos serie disponibles en Windows: ${availablePorts.length}');
          
          for (final portName in availablePorts) {
            try {
              final port = SerialPort(portName);
              final description = port.description;
              final manufacturer = port.manufacturer;
              final productName = port.productName;
              final serialNumber = port.serialNumber;
              
              debugPrint('Puerto encontrado: $portName');
              debugPrint('- Descripción: $description');
              debugPrint('- Fabricante: $manufacturer');
              debugPrint('- Producto: $productName');
              debugPrint('- Número de serie: $serialNumber');
              
              // Verificar si es un ESP32 basado en la descripción o fabricante
              final isEsp32 = _isWindowsEsp32Device(description, manufacturer, productName);
              
              _devices.add({
                'portName': portName,
                'description': description,
                'manufacturer': manufacturer,
                'productName': productName,
                'serialNumber': serialNumber,
                'isEsp32': isEsp32,
              });
              
              port.close();
            } catch (e) {
              debugPrint('Error al obtener información del puerto $portName: $e');
            }
          }
        } catch (e) {
          debugPrint('Error al listar puertos en Windows: $e');
          _devices = [];
        }
      } else {
        // En Android, usar usb_serial
        try {
          final usbDevices = await UsbSerial.listDevices();
          _devices = usbDevices;
          
          debugPrint('Dispositivos USB encontrados en Android: ${_devices.length}');
          
          for (final device in usbDevices) {
            final vid = device.vid?.toRadixString(16).toUpperCase() ?? 'unknown';
            final pid = device.pid?.toRadixString(16).toUpperCase() ?? 'unknown';
            final isEsp32 = _isEsp32Device(device);
            
            debugPrint('Dispositivo encontrado:');
            debugPrint('- VID: $vid');
            debugPrint('- PID: $pid');
            debugPrint('- Tipo: ${isEsp32 ? "ESP32" : "Otro dispositivo"}');
            debugPrint('- Nombre: ${device.productName ?? "Desconocido"}');
            debugPrint('- Fabricante: ${device.manufacturerName ?? "Desconocido"}');
            debugPrint('------------------------');
          }
        } catch (e) {
          debugPrint('Error al listar dispositivos USB en Android: $e');
          _devices = [];
        }
      }
      
      if (_devices.isEmpty) {
        debugPrint('No se encontraron dispositivos. Verifica la conexión y los drivers.');
        debugPrint('Asegúrate de:');
        debugPrint('1. Tener instalados los drivers correctos');
        debugPrint('2. El dispositivo esté conectado correctamente');
        debugPrint('3. El dispositivo aparezca en el Administrador de dispositivos');
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error al listar dispositivos: $e');
      // No lanzar excepción aquí para evitar bloquear la app
    }
  }
  
  // Check if a device is an ESP32 (for Android)
  bool _isEsp32Device(UsbDevice device) {
    final vid = device.vid?.toRadixString(16).toUpperCase() ?? '';
    final pid = device.pid?.toRadixString(16).toUpperCase() ?? '';
    
    for (final entry in _esp32Identifiers.entries) {
      if (entry.value[0] == vid && entry.value[1] == pid) {
        debugPrint('Dispositivo ESP32 detectado: ${entry.key} (VID=$vid, PID=$pid)');
        return true;
      }
    }
    
    return false;
  }
  
  // Check if a Windows serial port is an ESP32
  bool _isWindowsEsp32Device(String? description, String? manufacturer, String? productName) {
    if (description == null && manufacturer == null && productName == null) {
      return false;
    }
    
    // Lista de términos comunes en dispositivos ESP32
    final esp32Terms = [
      'cp210', 'silicon labs', 'cp2102', 'ch340', 'ch341', 'ftdi', 'usb to uart', 
      'usb-serial', 'uart bridge', 'esp32', 'espressif'
    ];
    
    // Verificar en la descripción
    if (description != null) {
      final lowerDesc = description.toLowerCase();
      for (final term in esp32Terms) {
        if (lowerDesc.contains(term)) {
          debugPrint('ESP32 detectado por descripción: $description');
          return true;
        }
      }
    }
    
    // Verificar en el fabricante
    if (manufacturer != null) {
      final lowerManuf = manufacturer.toLowerCase();
      for (final term in esp32Terms) {
        if (lowerManuf.contains(term)) {
          debugPrint('ESP32 detectado por fabricante: $manufacturer');
          return true;
        }
      }
    }
    
    // Verificar en el nombre del producto
    if (productName != null) {
      final lowerProduct = productName.toLowerCase();
      for (final term in esp32Terms) {
        if (lowerProduct.contains(term)) {
          debugPrint('ESP32 detectado por nombre de producto: $productName');
          return true;
        }
      }
    }
    
    return false;
  }
  
  // Connect to a device
  Future<bool> connect(dynamic device) async {
    try {
      // Disconnect if already connected
      if (_isConnected) {
        debugPrint('Desconectando dispositivo anterior...');
        await disconnect();
      }
      
      // Cancel mock data if active
      _mockDataTimer?.cancel();
      
      if (Platform.isWindows) {
        // Conectar en Windows usando libserialport
        return await _connectWindows(device);
      } else {
        // Conectar en Android usando usb_serial
        return await _connectAndroid(device);
      }
    } catch (e) {
      debugPrint('Error al conectar: $e');
     
      return false;
    }
  }
  
  // Connect on Windows platform
  Future<bool> _connectWindows(Map<String, dynamic> device) async {
    try {
      final portName = device['portName'] as String;
      final isEsp32 = device['isEsp32'] as bool;
      
      debugPrint('Intentando conectar al puerto: $portName');
      debugPrint('- Descripción: ${device['description']}');
      debugPrint('- Tipo: ${isEsp32 ? "ESP32" : "Otro dispositivo"}');
      
      // Crear y abrir el puerto serie
      _serialPort = SerialPort(portName);
      
      if (!_serialPort!.openReadWrite()) {
        final errorMessage = "Error al abrir el puerto: $portName";
        debugPrint(errorMessage);
       
        return false;
      }
      
      // Configurar parámetros del puerto
      try {
        _serialPort!.config = SerialPortConfig()
          ..baudRate = 115200
          ..bits = 8
          ..stopBits = 1
          ..parity = SerialPortParity.none
          ..setFlowControl(SerialPortFlowControl.none);
        
        debugPrint('Puerto serie configurado: 115200 baudios, 8N1');
      } catch (e) {
        debugPrint('Error al configurar el puerto serie: $e');
        // Intentar con configuración alternativa si falla
        try {
          _serialPort!.config = SerialPortConfig()
            ..baudRate = 9600  // Intentar con velocidad alternativa común
            ..bits = 8
            ..stopBits = 1
            ..parity = SerialPortParity.none
            ..setFlowControl(SerialPortFlowControl.none);
          
          debugPrint('Puerto serie configurado con velocidad alternativa: 9600 baudios, 8N1');
        } catch (e) {
          debugPrint('Error al configurar el puerto con velocidad alternativa: $e');
          throw Exception('No se pudo configurar el puerto serie');
        }
      }
      
      // Crear lector de puerto serie
      _serialPortReader = SerialPortReader(_serialPort!);
      
      // Suscribirse al stream de datos
      _winSubscription = _serialPortReader!.stream.listen(
        (Uint8List data) {
          final dataString = utf8.decode(data, allowMalformed: true);
          debugPrint('Datos recibidos: $dataString');
          _processWindowsData(dataString);
        },
        onError: (error) {
          debugPrint('Error en la lectura de datos: $error');
        },
      );
      
      // Port is open, update connection status immediately
      _lastValidDataTime = DateTime.now();
      _isConnected = true;
      notifyListeners();
      debugPrint('Puerto serie abierto en Windows, conexión establecida');
      return true;
    } catch (e) {
      debugPrint('Error al conectar en Windows: $e');
     
      return false;
    }
  }
  
  // Connect on Android platform
  Future<bool> _connectAndroid(UsbDevice device) async {
    try {
      final vid = device.vid?.toRadixString(16).toUpperCase() ?? 'unknown';
      final pid = device.pid?.toRadixString(16).toUpperCase() ?? 'unknown';
      final isEsp32 = _isEsp32Device(device);
      
      debugPrint('Intentando conectar al dispositivo:');
      debugPrint('- VID: $vid');
      debugPrint('- PID: $pid');
      debugPrint('- Tipo: ${isEsp32 ? "ESP32" : "Otro dispositivo"}');
      debugPrint('- Nombre: ${device.productName ?? "Desconocido"}');
      
      // Connect to the device
      _port = await device.create();
      if (_port == null) {
        debugPrint('Error: No se pudo crear el puerto USB');
  
        return false;
      }
      
      // Configure port
      bool openResult = await _port!.open();
      if (!openResult) {
        debugPrint('Error: No se pudo abrir el puerto USB');
        debugPrint('Verifica que:');
        debugPrint('1. No haya otra aplicación usando el puerto');
        debugPrint('2. Tengas permisos de administrador');
        debugPrint('3. Los drivers estén instalados correctamente');
        
        return false;
      }
      
      debugPrint('Puerto USB abierto exitosamente');
      
      // Configure port parameters (115200 baudios as specified)
      await _port!.setDTR(true);
      await _port!.setRTS(true);
      await _port!.setPortParameters(
        115200, // Baud rate
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );
      
      debugPrint('Parámetros del puerto configurados: 115200 baudios, 8N1');
      
      // Create transaction for reading data
      _transaction = Transaction.stringTerminated(
        _port!.inputStream!,
        Uint8List.fromList([13, 10]), // Terminate with CR+LF
      );
      
      // Subscribe to data stream
      _subscription = _transaction!.stream.listen(
        (String data) {
          debugPrint('Datos recibidos: $data');
          _processData(data);
        },
        onError: (error) {
          debugPrint('Error en la lectura de datos: $error');
        },
      );
      
      // Port is open, update connection status immediately
      _lastValidDataTime = DateTime.now();
      _isConnected = true;
      notifyListeners();
      debugPrint('Puerto USB abierto en Android, conexión establecida');
      return true;
    } catch (e) {
      debugPrint('Error al conectar en Android: $e');
    
      return false;
    }
  }
  
  // Disconnect from device
  Future<void> disconnect() async {
    try {
      if (Platform.isWindows) {
        // Desconectar en Windows
        if (_winSubscription != null) {
          await _winSubscription!.cancel();
          _winSubscription = null;
        }
        
        if (_serialPortReader != null) {
          _serialPortReader = null;
        }
        
        if (_serialPort != null) {
          _serialPort!.close();
          _serialPort!.dispose();
          _serialPort = null;
        }
      } else {
        // Desconectar en Android
        if (_subscription != null) {
          await _subscription!.cancel();
          _subscription = null;
        }
        
        if (_port != null) {
          await _port!.close();
          _port = null;
        }
      }
      
      _isConnected = false;
      notifyListeners();
      debugPrint('Dispositivo desconectado');
    } catch (e) {
      debugPrint('Error al desconectar: $e');
    }
  }
  
  // Process received data (Android)
  void _processData(String data) {
    try {
      debugPrint('Raw data received (Android): $data');
      
      // Add to buffer for handling fragmented data
      _dataBuffer += data;
      
      // Clean up the data
      final cleanData = _dataBuffer.trim();
      if (cleanData.isEmpty) {
        debugPrint('Skipping empty data');
        return;
      }
      
      // Check if we have a complete measurement set (indicated by separator lines)
      if (_dataBuffer.contains('---------------')) {
        // Split the buffer by the separator
        final measurements = _dataBuffer.split('---------------');
        
        // Process complete measurements (all except possibly the last one)
        for (int i = 0; i < measurements.length - 1; i++) {
          _processMeasurementSet(measurements[i]);
        }
        
        // Keep the last part in the buffer (might be incomplete)
        _dataBuffer = measurements.last;
        
        // If buffer gets too large, clear it to prevent memory issues
        if (_dataBuffer.length > 2000) {
          debugPrint('Buffer too large, clearing it');
          _dataBuffer = '';
        }
        
        // Update last valid data time since we received valid data
        _updateLastValidDataTime();
        return;
      }
      
      // For single line data that contains sensor information
      if (cleanData.contains(':') || cleanData.contains('=')) {
        debugPrint('Processing potential sensor data: $cleanData');
        
        // Parse data into SensorData object
        try {
          final sensorData = SensorData.fromString(cleanData);
          
          // Verify if the data is valid using the isValid method
          if (sensorData.isValid()) {
            debugPrint('Valid sensor data parsed: Temp=${sensorData.temperature}, Hum=${sensorData.humidity}');
            _dataStreamController.add(sensorData);
            
            // Update last valid data time since we received valid data
            _updateLastValidDataTime();
            
            // Clear buffer after successful processing
            _dataBuffer = '';
          } else {
            debugPrint('Parsed data failed validation, discarding');
            
            // Keep buffer for potential completion with more data
            // But limit its size to prevent memory issues
            if (_dataBuffer.length > 1000) {
              debugPrint('Buffer too large with no valid data, clearing it');
              _dataBuffer = '';
            }
          }
        } catch (e) {
          debugPrint('Error parsing sensor data: $e');
          debugPrint('Problematic data: $cleanData');
        }
      } else {
        debugPrint('Line does not contain sensor data format (no : or = found): $cleanData');
        
        // If the buffer gets too large without valid data, clear it
        if (_dataBuffer.length > 1000) {
          debugPrint('Buffer too large with no valid format, clearing it');
          _dataBuffer = '';
        }
      }
    } catch (e) {
      debugPrint('Error procesando datos: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      
      // Reset buffer on error to prevent cascading issues
      _dataBuffer = '';
    }
  }
  
  // Process received data (Windows)
  void _processWindowsData(String data) {
    try {
      debugPrint('Raw data received: $data');
      
      // Add new data to buffer
      _dataBuffer += data;
      
      // Clean up any leading/trailing whitespace in buffer
      _dataBuffer = _dataBuffer.trim();
      
      // Process individual lines for immediate feedback
      final lines = data.split('\n');
      for (final line in lines) {
        final cleanLine = line.trim();
        if (cleanLine.isEmpty) {
          debugPrint('Skipping empty line');
          continue;
        }
        
        debugPrint('Datos recibidos: $cleanLine');
        
        // Try to process individual lines that might contain complete sensor data
        if (cleanLine.contains(':') && !cleanLine.endsWith(':')) {
          debugPrint('Processing potential sensor data: $cleanLine');
          
          try {
            final sensorData = SensorData.fromString(cleanLine);
            
            // Check if we got valid data using the isValid method
            if (sensorData.isValid()) {
              debugPrint('Valid sensor data parsed: Temp=${sensorData.temperature}, Hum=${sensorData.humidity}');
              _dataStreamController.add(sensorData);
              // Update last valid data time
              _updateLastValidDataTime();
            } else {
              debugPrint('Parsed data failed validation, discarding');
            }
          } catch (e) {
            debugPrint('Error parsing individual line: $e');
          }
        } else if (!cleanLine.contains(':') && cleanLine.contains('%')) {
          // This might be a percentage value for humidity or fertility
          debugPrint('Line contains percentage value: $cleanLine');
        } else if (cleanLine.contains('---------------')) {
          debugPrint('Separator line detected');
        } else {
          debugPrint('Line does not contain sensor data format (no : or = found): $cleanLine');
        }
      }
      
      // Check if we have a complete measurement set (indicated by separator lines)
      if (_dataBuffer.contains('---------------')) {
        // Split the buffer by the separator
        final measurements = _dataBuffer.split('---------------');
        
        // Process complete measurements (all except possibly the last one)
        for (int i = 0; i < measurements.length - 1; i++) {
          _processMeasurementSet(measurements[i]);
        }
        
        // Keep the last part in the buffer (might be incomplete)
        _dataBuffer = measurements.last;
        
        // If buffer gets too large, clear it to prevent memory issues
        if (_dataBuffer.length > 2000) {
          debugPrint('Buffer too large, clearing it');
          _dataBuffer = '';
        }
      } else {
        // If no separator found but buffer is getting large, try to process it anyway
        if (_dataBuffer.length > 1000) {
          debugPrint('Large buffer without separator, attempting to process');
          _processMeasurementSet(_dataBuffer);
          _dataBuffer = '';
        }
      }
    } catch (e) {
      debugPrint('Error procesando datos en Windows: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      
      // Reset buffer on error to prevent cascading issues
      if (_dataBuffer.length > 500) {
        _dataBuffer = '';
      }
    }
  }
  
  // Process a complete measurement set
  void _processMeasurementSet(String measurementSet) {
    try {
      debugPrint('Processing complete measurement set');
      
      // Clean up the measurement set
      final cleanSet = measurementSet.trim();
      if (cleanSet.isEmpty) {
        debugPrint('Empty measurement set, skipping');
        return;
      }
      
      // Extract all key-value pairs from the measurement set
      final Map<String, double> values = {};
      
      // Regular expressions to match different sensor data formats
      final tempRegex = RegExp(r'Temperatura:?\s*(\d+\.?\d*)(?:\s*°C)?');
      final humRegex = RegExp(r'Humedad:?\s*(\d+\.?\d*)');
      final condRegex = RegExp(r'Conductividad:?\s*(\d+\.?\d*)(?:\s*dS)?');
      final phRegex = RegExp(r'pH:?\s*(\d+\.?\d*)');
      final nRegex = RegExp(r'N:?\s*(\d+\.?\d*)(?:\s*mg\/kg)?');
      final pRegex = RegExp(r'P:?\s*(\d+\.?\d*)(?:\s*mg\/kg)?');
      final kRegex = RegExp(r'K:?\s*(\d+\.?\d*)(?:\s*mg\/kg)?');
      final fertRegex = RegExp(r'(?:[Ff]ert(?:ilidad)?|ilidad):?\s*(\d+\.?\d*)(?:\s*%)?');
      
      // Extract temperature
      final tempMatch = tempRegex.firstMatch(cleanSet);
      if (tempMatch != null && tempMatch.groupCount >= 1) {
        values['temp'] = double.tryParse(tempMatch.group(1) ?? '0') ?? 0.0;
        debugPrint('Extracted temperature: ${values['temp']}');
      }
      
      // Extract humidity
      final humMatch = humRegex.firstMatch(cleanSet);
      if (humMatch != null && humMatch.groupCount >= 1) {
        values['hum'] = double.tryParse(humMatch.group(1) ?? '0') ?? 0.0;
        debugPrint('Extracted humidity: ${values['hum']}');
      } else {
        // Try to find humidity value that might be split across lines
        final percentMatch = RegExp(r'(\d+\.?\d*)\s*%').firstMatch(cleanSet);
        if (percentMatch != null && percentMatch.groupCount >= 1 && 
            (cleanSet.contains('Humedad') || cleanSet.contains('humedad')) && 
            !cleanSet.contains('Fertilidad') && !cleanSet.contains('ilidad')) {
          values['hum'] = double.tryParse(percentMatch.group(1) ?? '0') ?? 0.0;
          debugPrint('Extracted humidity from percentage: ${values['hum']}');
        }
      }
      
      // Extract conductivity
      final condMatch = condRegex.firstMatch(cleanSet);
      if (condMatch != null && condMatch.groupCount >= 1) {
        values['cond'] = double.tryParse(condMatch.group(1) ?? '0') ?? 0.0;
        debugPrint('Extracted conductivity: ${values['cond']}');
      }
      
      // Extract pH
      final phMatch = phRegex.firstMatch(cleanSet);
      if (phMatch != null && phMatch.groupCount >= 1) {
        values['ph'] = double.tryParse(phMatch.group(1) ?? '0') ?? 0.0;
        debugPrint('Extracted pH: ${values['ph']}');
      }
      
      // Extract nitrogen (N)
      final nMatch = nRegex.firstMatch(cleanSet);
      if (nMatch != null && nMatch.groupCount >= 1) {
        values['nut'] = double.tryParse(nMatch.group(1) ?? '0') ?? 0.0;
        debugPrint('Extracted nitrogen: ${values['nut']}');
      }
      
      // Extract phosphorus (P)
      final pMatch = pRegex.firstMatch(cleanSet);
      if (pMatch != null && pMatch.groupCount >= 1) {
        // Store as additional nutrient info if needed
        final pValue = double.tryParse(pMatch.group(1) ?? '0') ?? 0.0;
        debugPrint('Extracted phosphorus: $pValue');
      }
      
      // Extract potassium (K)
      final kMatch = kRegex.firstMatch(cleanSet);
      if (kMatch != null && kMatch.groupCount >= 1) {
        // Store as additional nutrient info if needed
        final kValue = double.tryParse(kMatch.group(1) ?? '0') ?? 0.0;
        debugPrint('Extracted potassium: $kValue');
      }
      
      // Extract fertility
      final fertMatch = fertRegex.firstMatch(cleanSet);
      if (fertMatch != null && fertMatch.groupCount >= 1) {
        values['fert'] = double.tryParse(fertMatch.group(1) ?? '0') ?? 0.0;
        debugPrint('Extracted fertility: ${values['fert']}');
      } else {
        // Try to find fertility value that might be split across lines
        final percentMatch = RegExp(r'(\d+\.?\d*)\s*%').firstMatch(cleanSet);
        if (percentMatch != null && percentMatch.groupCount >= 1 && 
            (cleanSet.contains('ilidad') || cleanSet.contains('Fertilidad'))) {
          values['fert'] = double.tryParse(percentMatch.group(1) ?? '0') ?? 0.0;
          debugPrint('Extracted fertility from percentage: ${values['fert']}');
        }
      }
      
      // Create sensor data object if we have at least some valid values
      if (values.isNotEmpty) {
        final sensorData = SensorData(
          temperature: values['temp'] ?? 0.0,
          humidity: values['hum'] ?? 0.0,
          conductivity: values['cond'] ?? 0.0,
          ph: values['ph'] ?? 0.0,
          nutrients: values['nut'] ?? 0.0,
          fertility: values['fert'] ?? 0.0,
          timestamp: DateTime.now(),
        );
        
        // Check if the data is valid using the isValid method
        if (sensorData.isValid()) {
          debugPrint('Valid sensor data parsed: Temp=${sensorData.temperature}, Hum=${sensorData.humidity}, pH=${sensorData.ph}');
          _dataStreamController.add(sensorData);
          // Update last valid data time
          _updateLastValidDataTime();
        } else {
          debugPrint('Parsed data failed validation, discarding');
        }
      } else {
        debugPrint('No valid sensor data found in measurement set');
      }
    } catch (e) {
      debugPrint('Error processing measurement set: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }
  
  // Send command to device
  Future<void> sendCommand(String command) async {
    if (!_isConnected) {
      debugPrint('No se puede enviar comando: dispositivo no conectado');
      return;
    }
    
    try {
      if (Platform.isWindows) {
        // Enviar comando en Windows
        if (_serialPort != null && _serialPort!.isOpen) {
          final data = Uint8List.fromList(utf8.encode('$command\r\n'));
          _serialPort!.write(data);
          debugPrint('Comando enviado en Windows: $command');
        }
      } else {
        // Enviar comando en Android
        if (_port != null) {
          await _port!.write(Uint8List.fromList(utf8.encode('$command\r\n')));
          debugPrint('Comando enviado en Android: $command');
        }
      }
    } catch (e) {
      debugPrint('Error enviando comando: $e');
    }
  }
  
  // For notifying listeners about changes
  final List<VoidCallback> _listeners = [];
  
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }
  
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }
  
  void notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }
  
  // Start connection validation timer
  void _startConnectionValidationTimer() {
    _connectionValidationTimer?.cancel();
    _connectionValidationTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _validateConnection();
    });
  }
  
  // Update last valid data time
  void _updateLastValidDataTime() {
    _lastValidDataTime = DateTime.now();
    // Reset consecutive timeouts counter when we receive valid data
    _consecutiveTimeoutsCount = 0;
    // If we were previously disconnected, update the connection status
    if (!_isConnected) {
      _isConnected = true;
      notifyListeners();
      debugPrint('Conexión validada: datos válidos recibidos');
    }
  }
  
  // Validate connection based on physical device presence only
  void _validateConnection() {
    bool physicallyConnected = false;
    
    // Check if a physical device is connected
    if (Platform.isWindows) {
      // For Windows, check if the serial port is open and valid
      physicallyConnected = _serialPort != null && _serialPort!.isOpen;
    } else {
      // For Android, check if the USB port is open
      physicallyConnected = _port != null;
    }
    
    // Update connection status based on physical connection only
    if (physicallyConnected) {
      // Device is physically connected, maintain connection regardless of data validity
      if (!_isConnected) {
        _isConnected = true;
        notifyListeners();
        debugPrint('Conexión física establecida: manteniendo conexión hasta desconexión física');
      }
      
      // If we have a valid data time, check if we need to send a ping to keep the connection alive
      if (_lastValidDataTime != null) {
        final timeSinceLastData = DateTime.now().difference(_lastValidDataTime!);
        
        if (timeSinceLastData.inSeconds > _connectionTimeoutSeconds) {
          // We have a physical connection but no valid data recently
          // Try to send a ping command to wake up the device, but don't disconnect
          debugPrint('Timeout detectado: $timeSinceLastData segundos sin datos válidos');
          debugPrint('Enviando comando de ping para verificar conexión...');
          sendCommand('ping');
          
          // Log the timeout but maintain connection
          debugPrint('Manteniendo conexión a pesar del timeout (según lo solicitado)');
        }
      }
    } else {
      // No physical connection detected - only case where we disconnect
      if (_isConnected) {
        _isConnected = false;
        notifyListeners();
        debugPrint('Conexión perdida: no hay dispositivo físico conectado');
        // No longer sending zero values when disconnected to prevent graph disorder
        // _dataStreamController.add(SensorData.zero());
      }
    }
  }
  
  // Dispose resources
  void dispose() {
    disconnect();
    _mockDataTimer?.cancel();
    _connectionValidationTimer?.cancel();
    _dataStreamController.close();
  }
}