import '../models/sensor_data.dart';
import '../models/garden.dart';

class GardenMeasurement {
  final int? id;
  final String gardenId;
  final SensorData sensorData;
  final DateTime timestamp;
  final String? notes;

  GardenMeasurement({
    this.id,
    required this.gardenId,
    required this.sensorData,
    required this.timestamp,
    this.notes,
  });

  // Convert to a map for database storage
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'garden_id': gardenId,
      'cultivo_id': null, // Set to null since this is a garden measurement
      'fecha': timestamp.toIso8601String(),
      'temperatura': sensorData.temperature,
      'humedad': sensorData.humidity,
      'conductividad': sensorData.conductivity,
      'ph': sensorData.ph,
      'nutrientes': sensorData.nutrients,
      'fertilidad': sensorData.fertility,
      if (notes != null) 'notas': notes,
    };
  }

  // Create from a database map
  factory GardenMeasurement.fromMap(Map<String, dynamic> map) {
    return GardenMeasurement(
      id: map['id'],
      gardenId: map['garden_id'],
      sensorData: SensorData(
        temperature: map['temperatura'] ?? 0.0,
        humidity: map['humedad'] ?? 0.0,
        conductivity: map['conductividad'] ?? 0.0,
        ph: map['ph'] ?? 0.0,
        nutrients: map['nutrientes'] ?? 0.0,
        fertility: map['fertilidad'] ?? 0.0,
        timestamp: DateTime.parse(map['fecha']),
      ),
      timestamp: DateTime.parse(map['fecha']),
      notes: map['notas'],
    );
  }

  // Create a copy with updated fields
  GardenMeasurement copyWith({
    int? id,
    String? gardenId,
    SensorData? sensorData,
    DateTime? timestamp,
    String? notes,
  }) {
    return GardenMeasurement(
      id: id ?? this.id,
      gardenId: gardenId ?? this.gardenId,
      sensorData: sensorData ?? this.sensorData,
      timestamp: timestamp ?? this.timestamp,
      notes: notes ?? this.notes,
    );
  }
}