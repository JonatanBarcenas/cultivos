// This is a stub file for non-Windows platforms
// It provides empty implementations of the SerialPort classes

class SerialPort {
  SerialPort(String portName);
  
  bool openReadWrite() => false;
  void close() {}
  void dispose() {}
  
  bool get isOpen => false;
  String get description => '';
  String get manufacturer => '';
  String get productName => '';
  String get serialNumber => '';
  
  static List<String> get availablePorts => [];
  
  // Stub for config setter
  set config(SerialPortConfig config) {}
}

class SerialPortConfig {
  int baudRate = 0;
  int bits = 0;
  int stopBits = 0;
  int parity = 0;
  
  void setFlowControl(int flowControl) {}
}

class SerialPortReader {
  SerialPortReader(SerialPort port);
  
  Stream<List<int>> get stream => Stream.empty();
}

class SerialPortParity {
  static const int none = 0;
}

class SerialPortFlowControl {
  static const int none = 0;
}