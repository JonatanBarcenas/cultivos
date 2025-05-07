class Garden {
  final String id;
  final String name;
  final String contact;
  final String location;
  final String cropType;
  final double? area;
  final String? notes;
  final String? irrigationType;
  final DateTime createdAt;

  Garden({
    required this.id,
    required this.name,
    required this.contact,
    required this.location,
    this.cropType = 'No especificado',
    this.area,
    this.notes,
    this.irrigationType,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Create a copy of the garden with updated fields
  Garden copyWith({
    String? id,
    String? name,
    String? contact,
    String? location,
    String? cropType,
    double? area,
    String? notes,
    String? irrigationType,
    DateTime? createdAt,
  }) {
    return Garden(
      id: id ?? this.id,
      name: name ?? this.name,
      contact: contact ?? this.contact,
      location: location ?? this.location,
      cropType: cropType ?? this.cropType,
      area: area ?? this.area,
      notes: notes ?? this.notes,
      irrigationType: irrigationType ?? this.irrigationType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Convert garden to a map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'contact': contact,
      'location': location,
      'crop_type': cropType,
      'area': area,
      'notes': notes,
      'irrigation_type': irrigationType,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Create a garden from a map
  factory Garden.fromMap(Map<String, dynamic> map) {
    return Garden(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      contact: map['contact'] ?? '',
      location: map['location'] ?? '',
      cropType: map['crop_type'] ?? 'No especificado',
      area: map['area'] != null ? (map['area'] is double ? map['area'] : double.tryParse(map['area'].toString())) : null,
      notes: map['notes'],
      irrigationType: map['irrigation_type'],
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : DateTime.now(),
    );
  }
}