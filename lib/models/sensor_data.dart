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

  factory SensorData.fromString(String dataString) {
    // Expected format: "temp:25.5,hum:60.2,cond:450,ph:6.8,nut:350,fert:75"
    final Map<String, double> values = {};
    final parts = dataString.split(',');
    
    for (final part in parts) {
      final keyValue = part.split(':');
      if (keyValue.length == 2) {
        final key = keyValue[0].trim();
        final value = double.tryParse(keyValue[1].trim()) ?? 0.0;
        values[key] = value;
      }
    }
    
    return SensorData(
      temperature: values['temp'] ?? 0.0,
      humidity: values['hum'] ?? 0.0,
      conductivity: values['cond'] ?? 0.0,
      ph: values['ph'] ?? 0.0,
      nutrients: values['nut'] ?? 0.0,
      fertility: values['fert'] ?? 0.0,
      timestamp: DateTime.now(),
    );
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
}