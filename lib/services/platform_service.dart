import 'dart:io';
import 'package:flutter/foundation.dart';

class PlatformService {
  // Platform detection methods
  static bool get isAndroid => Platform.isAndroid;
  static bool get isWindows => Platform.isWindows;
  static bool get isIOS => Platform.isIOS;
  
  // Determine which serial port implementation to use
  static bool get useLibSerialPort => isWindows;
  
  // Helper method to get current platform name
  static String get platformName {
    if (isAndroid) return 'Android';
    if (isWindows) return 'Windows';
    if (isIOS) return 'iOS';
    return 'Unknown';
  }
}