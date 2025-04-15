class CropDiagnostic {
  final String id;
  final String name;
  final double growthProbability;
  final String description;
  final Map<String, List<double>> optimalConditions; // Map of sensor type to [min, max] values

  CropDiagnostic({
    required this.id,
    required this.name,
    required this.growthProbability,
    required this.description,
    required this.optimalConditions,
  });

  // Create a copy with updated fields
  CropDiagnostic copyWith({
    String? id,
    String? name,
    double? growthProbability,
    String? description,
    Map<String, List<double>>? optimalConditions,
  }) {
    return CropDiagnostic(
      id: id ?? this.id,
      name: name ?? this.name,
      growthProbability: growthProbability ?? this.growthProbability,
      description: description ?? this.description,
      optimalConditions: optimalConditions ?? this.optimalConditions,
    );
  }

  // Convert to a map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'growthProbability': growthProbability,
      'description': description,
      'optimalConditions': optimalConditions,
    };
  }

  // Create from a map
  factory CropDiagnostic.fromMap(Map<String, dynamic> map) {
    return CropDiagnostic(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      growthProbability: map['growthProbability'] ?? 0.0,
      description: map['description'] ?? '',
      optimalConditions: Map<String, List<double>>.from(
        (map['optimalConditions'] as Map<String, dynamic>? ?? {}).map(
          (key, value) => MapEntry(key, List<double>.from(value)),
        ),
      ),
    );
  }

  // Calculate growth probability based on current sensor data
  static double calculateProbability(Map<String, double> currentConditions, Map<String, List<double>> optimalConditions) {
    if (currentConditions.isEmpty || optimalConditions.isEmpty) {
      return 0.0;
    }

    double totalScore = 0.0;
    int factorsCount = 0;

    optimalConditions.forEach((factor, range) {
      if (currentConditions.containsKey(factor) && range.length >= 2) {
        double min = range[0];
        double max = range[1];
        double current = currentConditions[factor]!;
        
        // Calculate how close the current value is to the optimal range
        double score = 0.0;
        if (current >= min && current <= max) {
          // Within optimal range
          score = 1.0;
        } else if (current < min) {
          // Below optimal range
          score = 1.0 - ((min - current) / min).clamp(0.0, 1.0);
        } else {
          // Above optimal range
          score = 1.0 - ((current - max) / max).clamp(0.0, 1.0);
        }
        
        totalScore += score;
        factorsCount++;
      }
    });

    return factorsCount > 0 ? (totalScore / factorsCount) * 100 : 0.0;
  }

  // Sample crop diagnostics for common crops
  static List<CropDiagnostic> getSampleCrops() {
    return [
      CropDiagnostic(
        id: '1',
        name: 'Tomate',
        growthProbability: 85.0,
        description: 'Cultivo de clima cálido que requiere buena exposición solar.',
        optimalConditions: {
          'temperature': [20.0, 30.0],
          'humidity': [60.0, 80.0],
          'ph': [5.5, 7.0],
          'conductivity': [200.0, 500.0],
        },
      ),
      CropDiagnostic(
        id: '2',
        name: 'Lechuga',
        growthProbability: 75.0,
        description: 'Prefiere climas frescos y suelos bien drenados.',
        optimalConditions: {
          'temperature': [15.0, 22.0],
          'humidity': [50.0, 70.0],
          'ph': [6.0, 7.0],
          'conductivity': [150.0, 400.0],
        },
      ),
      CropDiagnostic(
        id: '3',
        name: 'Zanahoria',
        growthProbability: 80.0,
        description: 'Cultivo de raíz que prefiere suelos sueltos y profundos.',
        optimalConditions: {
          'temperature': [15.0, 25.0],
          'humidity': [50.0, 70.0],
          'ph': [6.0, 7.5],
          'conductivity': [100.0, 300.0],
        },
      ),
      CropDiagnostic(
        id: '4',
        name: 'Pimiento',
        growthProbability: 70.0,
        description: 'Requiere temperaturas cálidas y buena exposición solar.',
        optimalConditions: {
          'temperature': [18.0, 30.0],
          'humidity': [50.0, 70.0],
          'ph': [5.5, 7.0],
          'conductivity': [150.0, 400.0],
        },
      ),
      CropDiagnostic(
        id: '5',
        name: 'Frijol',
        growthProbability: 90.0,
        description: 'Cultivo adaptable que mejora la calidad del suelo.',
        optimalConditions: {
          'temperature': [18.0, 28.0],
          'humidity': [40.0, 60.0],
          'ph': [6.0, 7.5],
          'conductivity': [100.0, 300.0],
        },
      ),
    ];
  }
}