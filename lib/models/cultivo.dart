class Cultivo {
  final int? id;
  final String nombre;
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final String estado;
  final String? notas;

  Cultivo({
    this.id,
    required this.nombre,
    required this.fechaInicio,
    this.fechaFin,
    required this.estado,
    this.notas,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'fecha_inicio': fechaInicio.toIso8601String(),
      'fecha_fin': fechaFin?.toIso8601String(),
      'estado': estado,
      'notas': notas,
    };
  }

  factory Cultivo.fromMap(Map<String, dynamic> map) {
    return Cultivo(
      id: map['id'],
      nombre: map['nombre'],
      fechaInicio: DateTime.parse(map['fecha_inicio']),
      fechaFin: map['fecha_fin'] != null ? DateTime.parse(map['fecha_fin']) : null,
      estado: map['estado'],
      notas: map['notas'],
    );
  }
} 