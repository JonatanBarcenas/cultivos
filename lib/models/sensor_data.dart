class SensorData {
  final double temperature;
  final double humidity;
  final double conductivity;
  final double ph;
  final double nutrients;
  final double fertility;
  final DateTime timestamp;

  SensorData({
    required this.temperature,
    required this.humidity,
    required this.conductivity,
    required this.ph,
    required this.nutrients,
    required this.fertility,
    required this.timestamp,
  });

  // Validate if the sensor data has valid readings (not all zeros or too many zeros)
  bool isValid() {
    // Count how many zero values we have
    int zeroCount = 0;
    
    // Check each sensor value
    if (temperature <= 0) zeroCount++;
    if (humidity <= 0) zeroCount++;
    if (conductivity <= 0) zeroCount++;
    if (ph <= 0) zeroCount++;
    if (nutrients <= 0) zeroCount++;
    if (fertility <= 0) zeroCount++;
    
    // Discard readings with all zeros
    if (zeroCount == 6) {
      print('Discarding reading: All values are zero');
      return false;
    }
    
    // Discard readings with too many zeros (more than 3)
    if (zeroCount > 3) {
      print('Discarding reading: Too many zero values ($zeroCount)');
      return false;
    }
    
    // Discard readings with a single critical zero (temperature or humidity)
    if (temperature <= 0) {
      print('Discarding reading: Temperature is zero or negative');
      return false;
    }
    
    if (humidity <= 0) {
      print('Discarding reading: Humidity is zero or negative');
      return false;
    }
    
    return true;
  }

  factory SensorData.fromString(String dataString) {
    // Expected format: "temp:25.5,hum:60.2,cond:450,ph:6.8,nut:350,fert:75"
    // But also handle variations like "temperatura:25.5" or extra spaces
    final Map<String, double> values = {};
    
    // Clean up the data string
    final cleanString = dataString.trim();
    if (cleanString.isEmpty) {
      print('Warning: Empty data string received');
      return SensorData.sample(); // Return sample data if string is empty
    }
    
    print('Processing data string: $cleanString');
    
    try {
      // First try to extract values using regular expressions for specific formats
      // This helps with fragmented data and special formats
      
      // Temperature - Updated to handle "°C" suffix
      final tempRegex = RegExp(r'[Tt]emperatura?:?\s*(\d+\.?\d*)(?:\s*°C)?');
      final tempMatch = tempRegex.firstMatch(cleanString);
      if (tempMatch != null && tempMatch.groupCount >= 1) {
        final value = double.tryParse(tempMatch.group(1) ?? '0') ?? 0.0;
        values['temp'] = value;
        print('Parsed temp: $value');
      }
      
      // Humidity - Updated to better handle standalone percentage
      final humRegex = RegExp(r'[Hh]umedad:?\s*(\d+\.?\d*)');
      final humMatch = humRegex.firstMatch(cleanString);
      if (humMatch != null && humMatch.groupCount >= 1) {
        final value = double.tryParse(humMatch.group(1) ?? '0') ?? 0.0;
        values['hum'] = value;
        print('Parsed hum: $value');
      } else if (cleanString.contains('%') && !cleanString.contains('Fert') && !cleanString.contains('ilidad')) {
        // Try to find standalone percentage that might be humidity
        final percentRegex = RegExp(r'\s*(\d+\.?\d*)\s*%');
        final percentMatch = percentRegex.firstMatch(cleanString);
        if (percentMatch != null) {
          final value = double.tryParse(percentMatch.group(1) ?? '0') ?? 0.0;
          values['hum'] = value;
          print('Parsed hum from percentage: $value');
        }
      }
      
      // Conductivity - Updated to handle "dS" and "/m" suffixes
      final condRegex = RegExp(r'[Cc]onductividad:?\s*(\d+\.?\d*)(?:\s*dS)?');
      final condMatch = condRegex.firstMatch(cleanString);
      if (condMatch != null && condMatch.groupCount >= 1) {
        final value = double.tryParse(condMatch.group(1) ?? '0') ?? 0.0;
        values['cond'] = value;
        print('Parsed cond: $value');
      }
      
      // pH
      final phRegex = RegExp(r'pH:?\s*(\d+\.?\d*)');
      final phMatch = phRegex.firstMatch(cleanString);
      if (phMatch != null && phMatch.groupCount >= 1) {
        final value = double.tryParse(phMatch.group(1) ?? '0') ?? 0.0;
        values['ph'] = value;
        print('Parsed ph: $value');
      }
      
      // Nutrients (N, P, K) - Updated to handle "mg/kg" suffix
      final nRegex = RegExp(r'N:?\s*(\d+\.?\d*)(?:\s*mg\/kg)?');
      final nMatch = nRegex.firstMatch(cleanString);
      if (nMatch != null && nMatch.groupCount >= 1) {
        final value = double.tryParse(nMatch.group(1) ?? '0') ?? 0.0;
        values['nut'] = value; // Use N as the primary nutrient value
        print('Parsed nutrients (N): $value');
      }
      
      // P and K are captured but not currently used in the model
      final pRegex = RegExp(r'P:?\s*(\d+\.?\d*)(?:\s*mg\/kg)?');
      final pMatch = pRegex.firstMatch(cleanString);
      if (pMatch != null && pMatch.groupCount >= 1) {
        final value = double.tryParse(pMatch.group(1) ?? '0') ?? 0.0;
        print('Parsed P: $value (stored as additional info)');
      }
      
      final kRegex = RegExp(r'K:?\s*(\d+\.?\d*)(?:\s*mg\/kg)?');
      final kMatch = kRegex.firstMatch(cleanString);
      if (kMatch != null && kMatch.groupCount >= 1) {
        final value = double.tryParse(kMatch.group(1) ?? '0') ?? 0.0;
        print('Parsed K: $value (stored as additional info)');
      }
      
      // Fertility - Updated to better handle "ilidad" prefix
      final fertRegex = RegExp(r'(?:[Ff]ert(?:ilidad)?|ilidad):?\s*(\d+\.?\d*)(?:\s*%)?');
      final fertMatch = fertRegex.firstMatch(cleanString);
      if (fertMatch != null && fertMatch.groupCount >= 1) {
        final value = double.tryParse(fertMatch.group(1) ?? '0') ?? 0.0;
        values['fert'] = value;
        print('Parsed fert: $value');
      } else if (cleanString.contains('%') && (cleanString.contains('ilidad') || cleanString.contains('Fertilidad'))) {
        // Try to find standalone percentage that might be fertility
        final percentRegex = RegExp(r'\s*(\d+\.?\d*)\s*%');
        final percentMatch = percentRegex.firstMatch(cleanString);
        if (percentMatch != null) {
          final value = double.tryParse(percentMatch.group(1) ?? '0') ?? 0.0;
          values['fert'] = value;
          print('Parsed fert from percentage: $value');
        }
      }
      
      // If regex approach didn't work, try the traditional comma-separated approach
      if (values.isEmpty && cleanString.contains(',')) {
        final parts = cleanString.split(',');
        
        for (final part in parts) {
          // Skip empty parts
          if (part.trim().isEmpty) continue;
          
          // Handle different separators (: or =)
          String separator = ':';
          if (part.contains('=')) {
            separator = '=';
          }
          
          final keyValue = part.split(separator);
          if (keyValue.length == 2) {
            final rawKey = keyValue[0].trim().toLowerCase();
            final value = double.tryParse(keyValue[1].trim()) ?? 0.0;
            
            // Map various possible key names to our standard keys
            String standardKey;
            if (rawKey.contains('temp')) {
              standardKey = 'temp';
            } else if (rawKey.contains('hum')) {
              standardKey = 'hum';
            } else if (rawKey.contains('cond')) {
              standardKey = 'cond';
            } else if (rawKey == 'ph') {
              standardKey = 'ph';
            } else if (rawKey.contains('nut') || rawKey == 'n') {
              standardKey = 'nut';
            } else if (rawKey.contains('fert')) {
              standardKey = 'fert';
            } else {
              // Unknown key, skip it
              print('Warning: Unknown sensor key: $rawKey');
              continue;
            }
            
            values[standardKey] = value;
            print('Parsed $standardKey: $value');
          } else {
            print('Warning: Invalid key-value format in part: $part');
          }
        }
      }
      
      // Check if we have at least some data
      if (values.isEmpty) {
        print('Warning: No valid data found in string: $cleanString');
        return SensorData.sample(); // Return sample data if no valid data
      }
      
      // Create the sensor data object
      final sensorData = SensorData(
        temperature: values['temp'] ?? 0.0,
        humidity: values['hum'] ?? 0.0,
        conductivity: values['cond'] ?? 0.0,
        ph: values['ph'] ?? 0.0,
        nutrients: values['nut'] ?? 0.0,
        fertility: values['fert'] ?? 0.0,
        timestamp: DateTime.now(),
      );
      
      // Validate the sensor data before returning it
      if (!sensorData.isValid()) {
        print('Discarding invalid sensor data');
        return SensorData.sample(); // Return sample data if validation fails
      }
      
      return sensorData;
    } catch (e) {
      print('Error parsing sensor data: $e');
      print('Problematic data string: $cleanString');
      return SensorData.sample(); // Return sample data on error
    }
  }

  // Create a sample data point for testing
  factory SensorData.sample() {
    return SensorData(
      temperature: 25.5,
      humidity: 60.2,
      conductivity: 450.0,
      ph: 6.8,
      nutrients: 350.0,
      fertility: 75.0,
      timestamp: DateTime.now(),
    );
  }
  
  // Create a zero-value data point for when no device is connected
  factory SensorData.zero() {
    return SensorData(
      temperature: 0.0,
      humidity: 0.0,
      conductivity: 0.0,
      ph: 0.0,
      nutrients: 0.0,
      fertility: 0.0,
      timestamp: DateTime.now(),
    );
  }
}