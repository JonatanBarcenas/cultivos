import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/garden.dart';
import '../database/database_helper.dart';
import 'garden_detail_screen.dart'; // <-- Add this line

class GardensScreen extends StatefulWidget {
  const GardensScreen({Key? key}) : super(key: key);

  @override
  State<GardensScreen> createState() => _GardensScreenState();
}

class _GardensScreenState extends State<GardensScreen> {
  List<Garden> _gardens = [];
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGardens();
  }

  // Load gardens from the database
  Future<void> _loadGardens() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final gardensData = await _databaseHelper.getGardens();
      final gardens = gardensData.map((map) => Garden.fromMap(map)).toList();
      
      setState(() {
        _gardens = gardens;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading gardens: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addGarden() {
    _showGardenDialog();
  }

  void _editGarden(Garden garden) {
    _showGardenDialog(garden: garden);
  }

  void _deleteGarden(Garden garden) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Está seguro que desea eliminar la huerta "${garden.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Delete from database
                await _databaseHelper.deleteGarden(garden.id);
                
                setState(() {
                  _gardens.removeWhere((g) => g.id == garden.id);
                });
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Huerta "${garden.name}" eliminada')),
                  );
                }
              } catch (e) {
                debugPrint('Error deleting garden: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error al eliminar la huerta')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showGardenDialog({Garden? garden}) {
    final nameController = TextEditingController(text: garden?.name ?? '');
    final locationController = TextEditingController(text: garden?.location ?? '');
    final contactController = TextEditingController(text: garden?.contact ?? '');
    final cropTypeController = TextEditingController(text: garden?.cropType ?? '');
    final areaController = TextEditingController(text: garden?.area?.toString() ?? '');
    final notesController = TextEditingController(text: garden?.notes ?? '');
    String irrigationType = garden?.irrigationType ?? 'Manual';
  
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(garden == null ? 'Agregar Huerta' : 'Editar Huerta'),
        content: StatefulBuilder(
          builder: (context, setStateDialog) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Ubicación'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: contactController,
                  decoration: const InputDecoration(labelText: 'Contacto'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: cropTypeController,
                  decoration: const InputDecoration(labelText: 'Tipo de Cultivo'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: areaController,
                  decoration: const InputDecoration(labelText: 'Área (m²)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                // Fecha de siembra
                Row(
                  children: [
                  ],
                ),
                const SizedBox(height: 8),
                // Tipo de riego
                DropdownButtonFormField<String>(
                  value: irrigationType,
                  items: [
                    'Manual',
                    'Goteo',
                    'Aspersión',
                    'Otro',
                  ].map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  )).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setStateDialog(() {
                        irrigationType = value;
                      });
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Tipo de Riego'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notas/Observaciones'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newGarden = Garden(
                id: garden?.id ?? UniqueKey().toString(),
                name: nameController.text,
                location: locationController.text,
                contact: contactController.text,
                cropType: cropTypeController.text,
                area: double.tryParse(areaController.text),
                notes: notesController.text,
                irrigationType: irrigationType,
                createdAt: garden?.createdAt ?? DateTime.now(),
              );
              if (garden == null) {
                await _databaseHelper.insertGarden(newGarden.toMap());
              } else {
                await _databaseHelper.updateGarden(newGarden.toMap());
              }
              await _loadGardens();
              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: Text(garden == null ? 'Agregar' : 'Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Administrar Huertas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _gardens.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.eco,
                                size: 64,
                                color: colorScheme.primary.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No hay huertas registradas',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _addGarden,
                                icon: const Icon(Icons.add),
                                label: const Text('Añadir Huerta'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _gardens.length,
                          itemBuilder: (context, index) {
                            final garden = _gardens[index];
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 16),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: Text(
                                  garden.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.person, size: 16),
                                        const SizedBox(width: 8),
                                        Text('Contacto: ${garden.contact}'),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 16),
                                        const SizedBox(width: 8),
                                        Text('Ubicación: ${garden.location}'),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: colorScheme.primary,
                                      ),
                                      onPressed: () => _editGarden(garden),
                                      tooltip: 'Editar',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _deleteGarden(garden),
                                      tooltip: 'Eliminar',
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => GardenDetailScreen(garden: garden),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addGarden,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        child: const Icon(Icons.add),
        tooltip: 'Añadir Huerta',
      ),
    );
  }
}