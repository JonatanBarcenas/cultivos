import 'package:flutter/material.dart';
import '../models/garden.dart';
import '../models/garden_measurement.dart';
import '../database/database_helper.dart';
import '../models/sensor_data.dart';
import 'reports_screen.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart'; // Add this package to pubspec.yaml

class GardenDetailScreen extends StatefulWidget {
  final Garden garden;
  const GardenDetailScreen({Key? key, required this.garden}) : super(key: key);

  @override
  State<GardenDetailScreen> createState() => _GardenDetailScreenState();
}

class _GardenDetailScreenState extends State<GardenDetailScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<GardenMeasurement> _measurements = [];
  bool _isLoading = true;

  // Updated method to generate PDF directly
  Future<void> _generatePdfAndOpenReports() async {
    // Show loading dialog
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
      final pdf = pw.Document();
      final garden = widget.garden;
      
      // Add garden information
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text('Informe de Huerta: ${garden.name}', 
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Garden details
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Detalles de la Huerta', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 10),
                    pw.Text('Nombre: ${garden.name}'),
                    pw.Text('Ubicación: ${garden.location}'),
                    pw.Text('Contacto: ${garden.contact}'),
                    pw.Text('Tipo de Cultivo: ${garden.cropType}'),
                    if (garden.area != null) pw.Text('Área: ${garden.area} m²'),
                    if (garden.irrigationType != null) pw.Text('Tipo de Riego: ${garden.irrigationType}'),
                    if (garden.notes != null && garden.notes!.isNotEmpty) pw.Text('Notas: ${garden.notes}'),
                    pw.Text('Fecha de Creación: ${DateFormat('dd/MM/yyyy').format(garden.createdAt)}'),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Measurements table
              if (_measurements.isEmpty)
                pw.Text('No hay mediciones registradas para esta huerta.', style: pw.TextStyle(fontStyle: pw.FontStyle.italic))
              else
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Historial de Mediciones', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 10),
                    pw.Table(
                      border: pw.TableBorder.all(),
                      columnWidths: {
                        0: const pw.FlexColumnWidth(2),
                        1: const pw.FlexColumnWidth(1),
                        2: const pw.FlexColumnWidth(1),
                        3: const pw.FlexColumnWidth(1),
                        4: const pw.FlexColumnWidth(1),
                        5: const pw.FlexColumnWidth(1),
                        6: const pw.FlexColumnWidth(1),
                      },
                      children: [
                        // Header row
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                          children: [
                            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Fecha', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Temp (°C)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Hum (%)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('pH', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Cond', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Nut', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Fert', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                          ],
                        ),
                        // Data rows
                        ..._measurements.map((measurement) {
                          final data = measurement.sensorData;
                          return pw.TableRow(
                            children: [
                              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(DateFormat('dd/MM/yyyy HH:mm').format(measurement.timestamp))),
                              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(data.temperature.toStringAsFixed(1))),
                              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(data.humidity.toStringAsFixed(1))),
                              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(data.ph.toStringAsFixed(2))),
                              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(data.conductivity.toStringAsFixed(2))),
                              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(data.nutrients.toStringAsFixed(1))),
                              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(data.fertility.toStringAsFixed(1))),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ],
                ),
            ];
          },
          footer: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(top: 1.0 * PdfPageFormat.cm),
              child: pw.Text(
                'Página ${context.pageNumber} de ${context.pagesCount}',
                style: pw.TextStyle(color: PdfColors.grey),
              ),
            );
          },
        ),
      );

      // Save the PDF
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/huerta_${garden.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      // Close the loading dialog
      if (mounted) Navigator.pop(context);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF generado: ${file.path}')),
        );
      }

      // Open the PDF file
      await OpenFile.open(file.path);
      
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar el PDF: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadMeasurements();
  }

  Future<void> _loadMeasurements() async {
    setState(() { _isLoading = true; });
    try {
      final maps = await _databaseHelper.getGardenMeasurements(widget.garden.id);
      final measurements = maps.map((map) => GardenMeasurement.fromMap(map)).toList();
      setState(() {
        _measurements = measurements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _isLoading = false; });
    }
  }

  Widget _buildMeasurementTile(GardenMeasurement measurement) {
    final data = measurement.sensorData;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      child: ListTile(
        title: Text('Fecha: ${measurement.timestamp.toLocal().toString().split(".")[0]}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Temperatura: ${data.temperature.toStringAsFixed(1)} °C'),
            Text('Humedad: ${data.humidity.toStringAsFixed(1)} %'),
            Text('Conductividad: ${data.conductivity.toStringAsFixed(1)}'),
            Text('pH: ${data.ph.toStringAsFixed(2)}'),
            Text('Nutrientes: ${data.nutrients.toStringAsFixed(1)}'),
            Text('Fertilidad: ${data.fertility.toStringAsFixed(1)}'),
            if (measurement.notes != null && measurement.notes!.isNotEmpty)
              Text('Notas: ${measurement.notes}')
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final garden = widget.garden;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles de la Huerta'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(garden.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Contacto: ${garden.contact}'),
                    Text('Ubicación: ${garden.location}'),
                    Text('Tipo de Cultivo: ${garden.cropType}'),
                    if (garden.area != null) Text('Área: ${garden.area} m²'),
                    if (garden.irrigationType != null) Text('Tipo de Riego: ${garden.irrigationType}'),
                    if (garden.notes != null && garden.notes!.isNotEmpty) Text('Notas: ${garden.notes}'),
                    Text('Creada: ${garden.createdAt.toLocal().toString().split(" ")[0]}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Historial de Mediciones',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.primary),
                ),
                ElevatedButton.icon(
                  onPressed: _generatePdfAndOpenReports,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Generar PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _measurements.isEmpty
                    ? const Text('No hay mediciones registradas para esta huerta.')
                    : Column(
                        children: _measurements.map(_buildMeasurementTile).toList(),
                      ),
          ],
        ),
      ),
    );
  }
}