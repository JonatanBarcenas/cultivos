import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/crop_diagnostic.dart';
import '../models/sensor_data.dart';
import '../main.dart'; // Added import for DashboardProvider

class DiagnosticScreen extends StatefulWidget {
  const DiagnosticScreen({Key? key}) : super(key: key);

  @override
  State<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends State<DiagnosticScreen> {
  final List<CropDiagnostic> _crops = CropDiagnostic.getSampleCrops();
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final latestData = Provider.of<DashboardProvider>(context).latestData;
    
    // Calculate current conditions map for probability calculation
    Map<String, double> currentConditions = {};
    if (latestData != null) {
      currentConditions = {
        'temperature': latestData.temperature,
        'humidity': latestData.humidity,
        'ph': latestData.ph,
        'conductivity': latestData.conductivity,
      };
    }
    
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Probabilidad de Crecimiento',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Basado en las condiciones actuales del sensor',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: latestData == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sensors_off,
                            size: 64,
                            color: colorScheme.primary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay datos de sensores disponibles',
                            style: TextStyle(
                              fontSize: 18,
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _crops.length,
                      itemBuilder: (context, index) {
                        final crop = _crops[index];
                        
                        // Calculate real-time probability based on current conditions
                        final probability = CropDiagnostic.calculateProbability(
                          currentConditions,
                          crop.optimalConditions,
                        );
                        
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      crop.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    _buildProbabilityBadge(probability),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(crop.description),
                                const SizedBox(height: 16),
                                const Text(
                                  'Condiciones Óptimas:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: crop.optimalConditions.entries.map((entry) {
                                    final sensorType = entry.key;
                                    final range = entry.value;
                                    String label;
                                    String value;
                                    
                                    switch (sensorType) {
                                      case 'temperature':
                                        label = 'Temperatura';
                                        value = '${range[0]} - ${range[1]} °C';
                                        break;
                                      case 'humidity':
                                        label = 'Humedad';
                                        value = '${range[0]} - ${range[1]} %';
                                        break;
                                      case 'ph':
                                        label = 'pH';
                                        value = '${range[0]} - ${range[1]}';
                                        break;
                                      case 'conductivity':
                                        label = 'Conductividad';
                                        value = '${range[0]} - ${range[1]} μS/cm';
                                        break;
                                      default:
                                        label = sensorType;
                                        value = '${range[0]} - ${range[1]}';
                                    }
                                    
                                    return Chip(
                                      avatar: Icon(
                                        _getIconForSensorType(sensorType),
                                        size: 16,
                                      ),
                                      label: Text('$label: $value'),
                                      backgroundColor: colorScheme.surfaceVariant,
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 16),
                                LinearProgressIndicator(
                                  value: probability / 100,
                                  backgroundColor: colorScheme.surfaceVariant,
                                  color: _getProbabilityColor(probability, colorScheme),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Probabilidad de éxito: ${probability.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _getProbabilityColor(probability, colorScheme),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProbabilityBadge(double probability) {
    Color color;
    String text;
    
    if (probability >= 80) {
      color = Colors.green;
      text = 'Excelente';
    } else if (probability >= 60) {
      color = Colors.lightGreen;
      text = 'Bueno';
    } else if (probability >= 40) {
      color = Colors.amber;
      text = 'Moderado';
    } else if (probability >= 20) {
      color = Colors.orange;
      text = 'Bajo';
    } else {
      color = Colors.red;
      text = 'Muy Bajo';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
  
  Color _getProbabilityColor(double probability, ColorScheme colorScheme) {
    if (probability >= 80) {
      return Colors.green;
    } else if (probability >= 60) {
      return Colors.lightGreen;
    } else if (probability >= 40) {
      return colorScheme.tertiary; // Amber/Orange
    } else if (probability >= 20) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
  
  IconData _getIconForSensorType(String sensorType) {
    switch (sensorType) {
      case 'temperature':
        return Icons.thermostat;
      case 'humidity':
        return Icons.water_drop;
      case 'ph':
        return Icons.science;
      case 'conductivity':
        return Icons.bolt;
      default:
        return Icons.sensors;
    }
  }
}