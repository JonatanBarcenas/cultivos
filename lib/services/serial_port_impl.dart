import 'dart:io';
import 'package:flutter/foundation.dart';

// Import the actual implementation or stub based on platform
export 'serial_port_windows.dart'
  if (dart.library.io) 'serial_port_windows.dart'
  if (dart.library.html) 'serial_port_stub.dart';