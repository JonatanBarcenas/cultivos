import 'package:flutter/material.dart';
import '../models/garden.dart';

class GardensScreen extends StatefulWidget {
  const GardensScreen({Key? key}) : super(key: key);

  @override
  State<GardensScreen> createState() => _GardensScreenState();
}

class _GardensScreenState extends State<GardensScreen> {
  final List<Garden> _gardens = [
    Garden(id: '1', name: 'Huerta Principal', contact: 'Juan Pérez', location: 'Zona Norte'),
    Garden(id: '2', name: 'Huerta Comunitaria', contact: 'María López', location: 'Zona Sur'),
    Garden(id: '3', name: 'Invernadero Central', contact: 'Carlos Rodríguez', location: 'Zona Este'),
  ];

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
            onPressed: () {
              setState(() {
                _gardens.removeWhere((g) => g.id == garden.id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Huerta "${garden.name}" eliminada')),
              );
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
    final isEditing = garden != null;
    final nameController = TextEditingController(text: garden?.name ?? '');
    final contactController = TextEditingController(text: garden?.contact ?? '');
    final locationController = TextEditingController(text: garden?.location ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Editar Huerta' : 'Añadir Huerta'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contactController,
                decoration: const InputDecoration(
                  labelText: 'Contacto',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Ubicación',
                  border: OutlineInputBorder(),
                ),
              ),
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
              final name = nameController.text.trim();
              final contact = contactController.text.trim();
              final location = locationController.text.trim();
              
              if (name.isEmpty || contact.isEmpty || location.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Por favor complete todos los campos')),
                );
                return;
              }
              
              setState(() {
                if (isEditing) {
                  // Update existing garden
                  final index = _gardens.indexWhere((g) => g.id == garden.id);
                  if (index != -1) {
                    _gardens[index] = Garden(
                      id: garden.id,
                      name: name,
                      contact: contact,
                      location: location,
                    );
                  }
                } else {
                  // Add new garden with a unique ID
                  _gardens.add(Garden(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name,
                    contact: contact,
                    location: location,
                  ));
                }
              });
              
              Navigator.pop(context);
            },
            child: Text(isEditing ? 'Actualizar' : 'Añadir'),
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
          'Huertas',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addGarden,
            tooltip: 'Añadir Huerta',
          ),
        ],
      ),
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
              child: _gardens.isEmpty
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
}