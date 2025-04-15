class Medicion {
  final int? id;
  final int cultivoId;
  final DateTime fecha;
  final double? temperatura;
  final double? humedad;
  final double? ph;

  Medicion({
    this.id,
    required this.cultivoId,
    required this.fecha,
    this.temperatura,
    this.humedad,
    this.ph,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cultivo_id': cultivoId,
      'fecha': fecha.toIso8601String(),
      'temperatura': temperatura,
      'humedad': humedad,
      'ph': ph,
    };
  }

  factory Medicion.fromMap(Map<String, dynamic> map) {
    return Medicion(
      id: map['id'],
      cultivoId: map['cultivo_id'],
      fecha: DateTime.parse(map['fecha']),
      temperatura: map['temperatura'],
      humedad: map['humedad'],
      ph: map['ph'],
    );
  }
} 