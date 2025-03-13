import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:usb_serial/transaction.dart';

import '../models/sensor_data.dart';

class SerialService {
  UsbPort? _port;
  StreamSubscription<String>? _subscription;
  Transaction<String>? _transaction;
  final StreamController<SensorData> _dataStreamController = StreamController<SensorData>.broadcast();
  
  // Expose stream of sensor data
  Stream<SensorData> get dataStream => _dataStreamController.stream;
  
  // Connection status
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  
  // Available ports
  List<UsbDevice> _devices = [];
  List<UsbDevice> get devices => _devices;
  
  // Constructor
  SerialService() {
    _init();
  }
  
  // Initialize the service
  Future<void> _init() async {
    await refreshDevices();
  }
  
  // Refresh available devices
  Future<void> refreshDevices() async {
    _devices = await UsbSerial.listDevices();
    notifyListeners();
  }
  
  // Connect to a device
  Future<bool> connect(UsbDevice device) async {
    // Disconnect if already connected
    if (_isConnected) {
      await disconnect();
    }
    
    // Connect to the device
    _port = await device.create();
    if (_port == null) {
      return false;
    }
    
    // Configure port
    bool openResult = await _port!.open();
    if (!openResult) {
      return false;
    }
    
    // Configure port parameters (115200 baudios as specified)
    await _port!.setDTR(true);
    await _port!.setRTS(true);
    await _port!.setPortParameters(
      115200, // Baud rate
      UsbPort.DATABITS_8,
      UsbPort.STOPBITS_1,
      UsbPort.PARITY_NONE,
    );
    
    // Create transaction for reading data
    _transaction = Transaction.stringTerminated(
      _port!.inputStream!,
      Uint8List.fromList([13, 10]), // Terminate with CR+LF
    );
    
    // Subscribe to data stream
    _subscription = _transaction!.stream.listen((String data) {
      // Process received data
      _processData(data);
    });
    
    _isConnected = true;
    notifyListeners();
    return true;
  }
  
  // Disconnect from device
  Future<void> disconnect() async {
    if (_subscription != null) {
      await _subscription!.cancel();
      _subscription = null;
    }
    
    if (_port != null) {
      await _port!.close();
      _port = null;
    }
    
    _isConnected = false;
    notifyListeners();
  }
  
  // Process received data
  void _processData(String data) {
    try {
      // Clean up the data
      final cleanData = data.trim();
      if (cleanData.isEmpty) return;
      
      // Parse data into SensorData object
      final sensorData = SensorData.fromString(cleanData);
      
      // Add to stream
      _dataStreamController.add(sensorData);
    } catch (e) {
      print('Error processing data: $e');
    }
  }
  
  // Send command to device
  Future<void> sendCommand(String command) async {
    if (_port == null || !_isConnected) return;
    
    try {
      await _port!.write(Uint8List.fromList(utf8.encode('$command\r\n')));
    } catch (e) {
      print('Error sending command: $e');
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
  
  // Dispose resources
  void dispose() {
    disconnect();
    _dataStreamController.close();
  }
}