class Garden {
  final String id;
  final String name;
  final String contact;
  final String location;

  Garden({
    required this.id,
    required this.name,
    required this.contact,
    required this.location,
  });

  // Create a copy of the garden with updated fields
  Garden copyWith({
    String? id,
    String? name,
    String? contact,
    String? location,
  }) {
    return Garden(
      id: id ?? this.id,
      name: name ?? this.name,
      contact: contact ?? this.contact,
      location: location ?? this.location,
    );
  }

  // Convert garden to a map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'contact': contact,
      'location': location,
    };
  }

  // Create a garden from a map
  factory Garden.fromMap(Map<String, dynamic> map) {
    return Garden(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      contact: map['contact'] ?? '',
      location: map['location'] ?? '',
    );
  }
}