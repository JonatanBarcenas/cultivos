import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:async';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

import '../models/sensor_data.dart';
import '../models/garden.dart';
import '../models/garden_measurement.dart';
import '../services/serial_service.dart';
import '../main.dart';
import '../database/database_helper.dart';

// Class to hold chart data
class ChartData {
  final DateTime timestamp;
  final double value;
  
  ChartData(this.timestamp, this.value);
}

// Recommendations class to hold all recommendation strings
class _Recommendations {
  final String temperature;
  final String humidity;
  final String ph;
  final String conductivity;
  final String nutrients;
  final String fertility;
  
  _Recommendations({
    required this.temperature,
    required this.humidity,
    required this.ph,
    required this.conductivity,
    required this.nutrients,
    required this.fertility,
  });
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<SensorData> _measurements = [];
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  StreamSubscription<SensorData>? _dataSubscription;
  
  @override
  void initState() {
    super.initState();
    // _loadRealData(); // <-- Elimina o comenta esta línea para que la tabla inicie vacía
    
    // Subscribe to real-time sensor data updates
    _subscribeToSensorData();
  }
  
  void _loadRealData() {
    // Get the data history from the provider
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
    
    // Filter out any invalid or zero readings
    final validData = dashboardProvider.dataHistory.where((data) =>
      data.temperature > 0 && data.humidity > 0 && 
      data.conductivity > 0 && data.ph > 0 && 
      data.nutrients > 0 && data.fertility > 0
    ).toList();
    
    setState(() {
      _measurements = List.from(validData);
    });
    
    // Log the number of valid measurements loaded
    debugPrint('Loaded ${_measurements.length} valid measurements from history');
  }
  
  void _subscribeToSensorData() {
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
    _dataSubscription = dashboardProvider.serialService.dataStream.listen((data) {
      // We don't add data automatically anymore
      debugPrint('New measurement received: Temp=${data.temperature.toStringAsFixed(1)}°C, Hum=${data.humidity.toStringAsFixed(1)}%, pH=${data.ph.toStringAsFixed(1)}');
    });
  }
  
  void _addMeasurement() {
    // Get the last valid measurement from the provider
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
    final lastValidData = dashboardProvider.dataHistory.lastWhere(
      (data) => data.temperature > 0 && data.humidity > 0 && 
                data.conductivity > 0 && data.ph > 0 && 
                data.nutrients > 0 && data.fertility > 0,
      orElse: () => SensorData(
        temperature: 0,
        humidity: 0,
        conductivity: 0,
        ph: 0,
        nutrients: 0,
        fertility: 0,
        timestamp: DateTime.now(),
      ),
    );

    // If no valid measurement was found, show a message
    if (lastValidData.temperature == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay lecturas válidas disponibles')),
      );
      return;
    }

    // Add the valid measurement to the table
    setState(() {
      _measurements.add(lastValidData);
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Medición agregada a la tabla')),
    );
  }

  Future<void> _saveMeasurement() async {
    // If there are no measurements, show a message
    if (_measurements.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay mediciones para guardar')),
      );
      return;
    }

    // Calculate averages
    double avgTemp = 0, avgHum = 0, avgCond = 0, avgPh = 0, avgNut = 0, avgFert = 0;
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

    // Create average measurement
    final averageMeasurement = SensorData(
      temperature: avgTemp,
      humidity: avgHum,
      conductivity: avgCond,
      ph: avgPh,
      nutrients: avgNut,
      fertility: avgFert,
      timestamp: DateTime.now(),
    );
    
    // Show dialog to select a garden
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Guardar Promedio en Huerta'),
        content: FutureBuilder<List<Garden>>(
          future: _databaseHelper.getGardens().then((maps) => 
            maps.map((map) => Garden.fromMap(map)).toList()
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text('No hay huertas disponibles. Por favor, cree una huerta primero.');
            }
            
            final gardens = snapshot.data!;
            return SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: gardens.length,
                itemBuilder: (context, index) {
                  final garden = gardens[index];
                  return ListTile(
                    title: Text(garden.name),
                    subtitle: Text(garden.location),
                    onTap: () async {
                      // Create a garden measurement with the average values
                      final gardenMeasurement = GardenMeasurement(
                        gardenId: garden.id,
                        sensorData: averageMeasurement,
                        timestamp: DateTime.now(),
                      );
                      
                      // Save to database
                      try {
                        await _databaseHelper.insertGardenMeasurement(gardenMeasurement.toMap());
                        
                        // Show success message
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Promedio guardado en ${garden.name}')),
                          );
                        }
                        
                        Navigator.pop(context);
                      } catch (e) {
                        debugPrint('Error saving measurement: $e');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Error al guardar la medición')),
                          );
                        }
                        Navigator.pop(context);
                      }
                    },
                  );
                },
          ),
            );
          },
        ),
        actions: [
          Container(
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Cancelar'),
            ),
          ),
        ],
      ),
    );
    // After saving, clear the table
    setState(() {
      _measurements.clear();
    });
  }
  @override
  void dispose() {
    // Cancel the subscription when the widget is disposed
    _dataSubscription?.cancel();
    super.dispose();
  }
  
  // Display measurements in a card with chart
  Widget _buildMeasurementsDisplay() {
    // If there are no measurements, show a friendly message instead of a progress indicator
    if (_measurements.isEmpty) {
      return const Center(
        child: Text(
          'No hay mediciones agregadas.\nPresiona el botón "+" para añadir una medición.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

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

    return Card(
      margin: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Fecha')),
              DataColumn(label: Text('Temperatura (°C)')),
              DataColumn(label: Text('Humedad (%)')),
              DataColumn(label: Text('pH')),
              DataColumn(label: Text('Conductividad (dS/m)')),
              DataColumn(label: Text('Nutrientes (ppm)')),
              DataColumn(label: Text('Fertilidad (%)')),
              DataColumn(label: Text('Acciones')),
            ],
            rows: [
              ..._measurements.map((data) => DataRow(
                cells: [
                  DataCell(Text(DateFormat('dd/MM/yyyy HH:mm').format(data.timestamp))),
                  DataCell(Text(data.temperature.toStringAsFixed(1))),
                  DataCell(Text(data.humidity.toStringAsFixed(1))),
                  DataCell(Text(data.ph.toStringAsFixed(1))),
                  DataCell(Text(data.conductivity.toStringAsFixed(2))),
                  DataCell(Text(data.nutrients.toStringAsFixed(1))),
                  DataCell(Text(data.fertility.toStringAsFixed(1))),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
              setState(() {
                          _measurements.remove(data);
              });
                      },
                    ),
                  ),
                ],
              )).toList(),
              // Promedio row
              DataRow(
                color: MaterialStateProperty.all(Colors.grey.withOpacity(0.2)),
                cells: [
                  const DataCell(Text('Promedio', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(avgTemp.toStringAsFixed(1))),
                  DataCell(Text(avgHum.toStringAsFixed(1))),
                  DataCell(Text(avgPh.toStringAsFixed(1))),
                  DataCell(Text(avgCond.toStringAsFixed(1))),
                  DataCell(Text(avgNut.toStringAsFixed(1))),
                  DataCell(Text(avgFert.toStringAsFixed(1))),
                  const DataCell(Text('')),
                ],
          ),
        ],
          ),
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- ADD BUTTONS HERE ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: _saveMeasurement,
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _exportToPdf,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Exportar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            _buildMeasurementsDisplay(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMeasurement,
        backgroundColor: Colors.green,
        elevation: 4,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Future<void> _exportToPdf() async {
    // If there are no measurements, show a message
    if (_measurements.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay mediciones para exportar')),
      );
      return;
    }
    
    // Show dialog to select a garden
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Huerta'),
        content: FutureBuilder<List<Garden>>(
          future: _databaseHelper.getGardens().then((maps) => 
            maps.map((map) => Garden.fromMap(map)).toList()
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text('No hay huertas disponibles. Por favor, cree una huerta primero.');
            }
            
            final gardens = snapshot.data!;
            return SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: gardens.length,
                itemBuilder: (context, index) {
                  final garden = gardens[index];
                  return ListTile(
                    title: Text(garden.name),
                    subtitle: Text(garden.location),
                    onTap: () async {
                      Navigator.pop(context);
                      await _generatePdfForGarden(garden);
                    },
                  );
                },
              ),
            );
          },
        ),
        actions: [
          Container(
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Cancelar'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePdfForGarden(Garden garden) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Generando PDF...'),
          ],
        ),
      ),
    );
    
    try {
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
      
      // Generate recommendations based on the averages
      final recommendations = _generateRecommendations(avgTemp, avgHum, avgPh, avgCond, avgNut, avgFert);
      
      // Create PDF document
      final pdf = pw.Document();
      
      // Add page to the PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (pw.Context context) {
            return pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Reporte de Mediciones', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(DateFormat('dd/MM/yyyy').format(DateTime.now()), style: const pw.TextStyle(fontSize: 14)),
                ],
              ),
            );
          },
          build: (pw.Context context) => [
            // Garden information
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Información de la Huerta', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Text('Nombre: ${garden.name}'),
                  pw.Text('Ubicación: ${garden.location}'),
                  pw.Text('Contacto: ${garden.contact}'),
                  pw.Text('Tipo de Cultivo: ${garden.cropType}'),
                  pw.Text('Fecha de Creación: ${DateFormat('dd/MM/yyyy').format(garden.createdAt)}'),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            
            // Measurements summary
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Resumen de Mediciones', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Text('Número de Mediciones: ${_measurements.length}'),
                  pw.Text('Período: ${DateFormat('dd/MM/yyyy').format(_measurements.first.timestamp)} - ${DateFormat('dd/MM/yyyy').format(_measurements.last.timestamp)}'),
                  pw.SizedBox(height: 16),
                  
                  // Measurements table
                  pw.Table(
                    border: pw.TableBorder.all(),
                    children: [
                      // Table header
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                        children: [
                          _pdfTableCell('Parámetro', isHeader: true),
                          _pdfTableCell('Promedio', isHeader: true),
                          _pdfTableCell('Estado', isHeader: true),
                        ],
                      ),
                      // Temperature row
                      pw.TableRow(
                        children: [
                          _pdfTableCell('Temperatura (°C)'),
                          _pdfTableCell(avgTemp.toStringAsFixed(1)),
                          _pdfTableCell(_getStatusText(avgTemp, 20, 30)),
                        ],
                      ),
                      // Humidity row
                      pw.TableRow(
                        children: [
                          _pdfTableCell('Humedad (%)'),
                          _pdfTableCell(avgHum.toStringAsFixed(1)),
                          _pdfTableCell(_getStatusText(avgHum, 40, 70)),
                        ],
                      ),
                      // pH row
                      pw.TableRow(
                        children: [
                          _pdfTableCell('pH'),
                          _pdfTableCell(avgPh.toStringAsFixed(1)),
                          _pdfTableCell(_getStatusText(avgPh, 6.0, 7.0)),
                        ],
                      ),
                      // Conductivity row
                      pw.TableRow(
                        children: [
                          _pdfTableCell('Conductividad (dS/m)'),
                          _pdfTableCell(avgCond.toStringAsFixed(2)),
                          _pdfTableCell(_getStatusText(avgCond, 0.5, 3.0)),
                        ],
                      ),
                      // Nutrients row
                      pw.TableRow(
                        children: [
                          _pdfTableCell('Nutrientes (ppm)'),
                          _pdfTableCell(avgNut.toStringAsFixed(1)),
                          _pdfTableCell(_getStatusText(avgNut, 1000, 1500)),
                        ],
                      ),
                      // Fertility row
                      pw.TableRow(
                        children: [
                          _pdfTableCell('Fertilidad (%)'),
                          _pdfTableCell(avgFert.toStringAsFixed(1)),
                          _pdfTableCell(_getStatusText(avgFert, 60, 90)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            
            // Recommendations
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Recomendaciones', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Text('Temperatura: ${recommendations.temperature}'),
                  pw.SizedBox(height: 4),
                  pw.Text('Humedad: ${recommendations.humidity}'),
                  pw.SizedBox(height: 4),
                  pw.Text('pH: ${recommendations.ph}'),
                  pw.SizedBox(height: 4),
                  pw.Text('Conductividad: ${recommendations.conductivity}'),
                  pw.SizedBox(height: 4),
                  pw.Text('Nutrientes: ${recommendations.nutrients}'),
                  pw.SizedBox(height: 4),
                  pw.Text('Fertilidad: ${recommendations.fertility}'),
                ],
              ),
            ),
          ],
        ),
      );
      
      // Save the PDF to a file
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/reporte_${garden.name}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf');
      await file.writeAsBytes(await pdf.save());
      
      // Close the loading dialog
      if (mounted) Navigator.pop(context);
      
      // Show success message with the file path
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF generado: ${file.path}'),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
      
      // Open the PDF file automatically
      await OpenFile.open(file.path);
      
    } catch (e) {
      // Close the loading dialog
      if (mounted) Navigator.pop(context);
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar el PDF: $e')),
        );
      }
    }
  }
  
  // Helper method to create a table cell for the PDF
  pw.Widget _pdfTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : null,
        ),
      ),
    );
  }
  
  // Helper method to get status text based on value and optimal range
  String _getStatusText(double value, double min, double max) {
    if (value < min) {
      return 'Bajo';
    } else if (value > max) {
      return 'Alto';
    } else {
      return 'Óptimo';
    }
  }
  
  // Generate recommendations based on measurements
  _Recommendations _generateRecommendations(double temp, double hum, double ph, double cond, double nut, double fert) {
    return _Recommendations(
      temperature: _getTemperatureRecommendation(temp),
      humidity: _getHumidityRecommendation(hum),
      ph: _getPhRecommendation(ph),
      conductivity: _getConductivityRecommendation(cond),
      nutrients: _getNutrientsRecommendation(nut),
      fertility: _getFertilityRecommendation(fert),
    );
  }
  
  String _getTemperatureRecommendation(double temp) {
    if (temp < 20) {
      return 'La temperatura es baja. Considere aumentar la temperatura del ambiente o usar mantas térmicas.';
    } else if (temp > 30) {
      return 'La temperatura es alta. Mejore la ventilación o use sistemas de enfriamiento.';
    } else {
      return 'La temperatura está en un rango óptimo. Mantenga las condiciones actuales.';
    }
  }
  
  String _getHumidityRecommendation(double hum) {
    if (hum < 40) {
      return 'La humedad es baja. Aumente el riego o use humidificadores.';
    } else if (hum > 70) {
      return 'La humedad es alta. Reduzca el riego y mejore la ventilación.';
    } else {
      return 'La humedad está en un rango óptimo. Mantenga las condiciones actuales.';
    }
  }
  
  String _getPhRecommendation(double ph) {
    if (ph < 6.0) {
      return 'El pH es bajo (ácido). Considere aplicar cal agrícola para aumentar el pH.';
    } else if (ph > 7.0) {
      return 'El pH es alto (alcalino). Considere aplicar azufre o compost ácido para reducir el pH.';
    } else {
      return 'El pH está en un rango óptimo. Mantenga las condiciones actuales.';
    }
  }
  
  String _getConductivityRecommendation(double cond) {
    if (cond < 0.5) {
      return 'La conductividad es baja. Aumente la aplicación de nutrientes solubles.';
    } else if (cond > 3.0) {
      return 'La conductividad es alta. Reduzca la aplicación de fertilizantes y considere lavar el sustrato.';
    } else {
      return 'La conductividad está en un rango óptimo. Mantenga las condiciones actuales.';
    }
  }
  
  String _getNutrientsRecommendation(double nut) {
    if (nut < 1000) {
      return 'El nivel de nutrientes es bajo. Aplique fertilizantes balanceados según las necesidades del cultivo.';
    } else if (nut > 1500) {
      return 'El nivel de nutrientes es alto. Reduzca la aplicación de fertilizantes.';
    } else {
      return 'El nivel de nutrientes está en un rango óptimo. Mantenga las condiciones actuales.';
    }
  }
  
  String _getFertilityRecommendation(double fert) {
    if (fert < 60) {
      return 'La fertilidad del suelo es baja. Aplique compost, abono orgánico o mejoradores de suelo.';
    } else if (fert > 90) {
      return 'La fertilidad del suelo es muy alta. Monitoree para evitar exceso de nutrientes.';
    } else {
      return 'La fertilidad del suelo está en un rango óptimo. Mantenga las condiciones actuales.';
    }
  }
}