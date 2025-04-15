import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/sensor_data.dart';
import '../models/garden.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final List<SensorData> _measurements = [];
  final List<Garden> _gardens = [
    Garden(id: '1', name: 'Huerta Principal', contact: 'Juan Pérez', location: 'Zona Norte'),
    Garden(id: '2', name: 'Huerta Comunitaria', contact: 'María López', location: 'Zona Sur'),
    Garden(id: '3', name: 'Invernadero Central', contact: 'Carlos Rodríguez', location: 'Zona Este'),
  ];
  
  @override
  void initState() {
    super.initState();
    // Add some sample data for demonstration
    _addSampleData();
  }
  
  void _addSampleData() {
    // Add sample measurements for demonstration purposes
    _measurements.addAll([
      SensorData(
        temperature: 24.5,
        humidity: 65.0,
        conductivity: 420.0,
        ph: 6.7,
        nutrients: 320.0,
        fertility: 72.0,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      SensorData(
        temperature: 26.2,
        humidity: 58.5,
        conductivity: 450.0,
        ph: 6.9,
        nutrients: 340.0,
        fertility: 75.0,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      SensorData(
        temperature: 25.8,
        humidity: 62.0,
        conductivity: 435.0,
        ph: 6.8,
        nutrients: 330.0,
        fertility: 73.0,
        timestamp: DateTime.now(),
      ),
    ]);
  }
  
  void _addMeasurement() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Añadir Medición'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMeasurementField('Temperatura (°C)', 'temperature'),
              _buildMeasurementField('Humedad (%)', 'humidity'),
              _buildMeasurementField('Conductividad (μS/cm)', 'conductivity'),
              _buildMeasurementField('pH', 'ph'),
              _buildMeasurementField('Nutrientes (ppm)', 'nutrients'),
              _buildMeasurementField('Fertilidad (%)', 'fertility'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // In a real app, we would validate and save the measurement
              // For demo purposes, just add a sample measurement
              setState(() {
                _measurements.add(SensorData.sample());
              });
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMeasurementField(String label, String field) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
      ),
    );
  }
  
  void _exportToPdf() {
    // Calculate averages
    double avgTemp = 0, avgHum = 0, avgCond = 0, avgPh = 0, avgNut = 0, avgFert = 0;
    
    if (_measurements.isNotEmpty) {
      for (var data in _measurements) {
        avgTemp += data.temperature;
        avgHum += data.humidity;
        avgCond += data.conductivity;
        avgPh += data.ph;
        avgNut += data.nutrients;
        avgFert += data.fertility;
      }
      
      avgTemp /= _measurements.length;
      avgHum /= _measurements.length;
      avgCond /= _measurements.length;
      avgPh /= _measurements.length;
      avgNut /= _measurements.length;
      avgFert /= _measurements.length;
    }
    
    // Show a dialog with the averages (in a real app, this would generate a PDF)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exportar Promedios'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Temperatura: ${avgTemp.toStringAsFixed(2)} °C'),
              Text('Humedad: ${avgHum.toStringAsFixed(2)} %'),
              Text('Conductividad: ${avgCond.toStringAsFixed(2)} μS/cm'),
              Text('pH: ${avgPh.toStringAsFixed(2)}'),
              Text('Nutrientes: ${avgNut.toStringAsFixed(2)} ppm'),
              Text('Fertilidad: ${avgFert.toStringAsFixed(2)} %'),
              const SizedBox(height: 16),
              const Text('En una aplicación real, estos promedios se exportarían a un archivo PDF.'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
  
  void _saveMeasurement() {
    // Show dialog to select a garden
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Guardar en Huerta'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _gardens.length,
            itemBuilder: (context, index) {
              final garden = _gardens[index];
              return ListTile(
                title: Text(garden.name),
                subtitle: Text(garden.location),
                onTap: () {
                  // In a real app, we would save the measurement to the selected garden
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Medición guardada en ${garden.name}')),
                  );
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.primaryContainer,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        title: Text(
          'Reportes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _addMeasurement,
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir Medición'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _exportToPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Exportar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.secondary,
                    foregroundColor: colorScheme.onSecondary,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _saveMeasurement,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.tertiary,
                    foregroundColor: colorScheme.onTertiary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Table title
            Text(
              'Tabla de Variables',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Data table
            Expanded(
              child: Card(
                elevation: 4,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Fecha/Hora')),
                        DataColumn(label: Text('Temperatura (°C)')),
                        DataColumn(label: Text('Humedad (%)')),
                        DataColumn(label: Text('pH')),
                        DataColumn(label: Text('Conductividad (μS/cm)')),
                        DataColumn(label: Text('Nutrientes (ppm)')),
                        DataColumn(label: Text('Fertilidad (%)')),
                      ],
                      rows: _measurements.map((data) {
                        return DataRow(
                          cells: [
                            DataCell(Text(DateFormat('dd/MM/yyyy HH:mm').format(data.timestamp))),
                            DataCell(Text(data.temperature.toStringAsFixed(1))),
                            DataCell(Text(data.humidity.toStringAsFixed(1))),
                            DataCell(Text(data.ph.toStringAsFixed(1))),
                            DataCell(Text(data.conductivity.toStringAsFixed(0))),
                            DataCell(Text(data.nutrients.toStringAsFixed(0))),
                            DataCell(Text(data.fertility.toStringAsFixed(1))),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}