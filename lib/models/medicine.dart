/// Model class for storing medicine information
/// Represents a single medication with essential details only
class Medicine {
  final String id; // Unique identifier
  final String name; // Medicine name (e.g., "Metformin")
  final String dosage; // Dosage amount (e.g., "500mg")
  final List<String> timesToTake; // When to take (e.g., ["Morning", "Evening"])
  final String? notes; // Optional additional notes
  final DateTime createdAt; // When medicine was added
  
  Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    required this.timesToTake,
    this.notes,
    required this.createdAt,
  });
  
  /// Convert Medicine object to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'timesToTake': timesToTake,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }
  
  /// Create Medicine object from JSON
  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'] as String,
      name: json['name'] as String,
      dosage: json['dosage'] as String,
      timesToTake: List<String>.from(json['timesToTake'] as List),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
  
  /// Create a copy of this Medicine with some fields updated
  Medicine copyWith({
    String? id,
    String? name,
    String? dosage,
    List<String>? timesToTake,
    String? notes,
    DateTime? createdAt,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      timesToTake: timesToTake ?? this.timesToTake,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
