/// Model class for storing medicine information
/// Represents a single medication with all its details
class Medicine {
  final String id; // Unique identifier
  final String name; // Medicine name (e.g., "Metformin")
  final String dosage; // Dosage amount (e.g., "500mg")
  final String doctorName; // Prescribing doctor
  final String? doctorPhone; // Optional doctor phone number
  final List<String> timesToTake; // When to take (e.g., ["Morning", "Evening"])
  final String? notes; // Optional additional notes
  final String? familyContact; // Optional family member contact
  final DateTime createdAt; // When medicine was added
  
  Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    required this.doctorName,
    this.doctorPhone,
    required this.timesToTake,
    this.notes,
    this.familyContact,
    required this.createdAt,
  });
  
  /// Convert Medicine object to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'doctorName': doctorName,
      'doctorPhone': doctorPhone,
      'timesToTake': timesToTake,
      'notes': notes,
      'familyContact': familyContact,
      'createdAt': createdAt.toIso8601String(),
    };
  }
  
  /// Create Medicine object from JSON
  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'] as String,
      name: json['name'] as String,
      dosage: json['dosage'] as String,
      doctorName: json['doctorName'] as String,
      doctorPhone: json['doctorPhone'] as String?,
      timesToTake: List<String>.from(json['timesToTake'] as List),
      notes: json['notes'] as String?,
      familyContact: json['familyContact'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
  
  /// Create a copy of this Medicine with some fields updated
  Medicine copyWith({
    String? id,
    String? name,
    String? dosage,
    String? doctorName,
    String? doctorPhone,
    List<String>? timesToTake,
    String? notes,
    String? familyContact,
    DateTime? createdAt,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      doctorName: doctorName ?? this.doctorName,
      doctorPhone: doctorPhone ?? this.doctorPhone,
      timesToTake: timesToTake ?? this.timesToTake,
      notes: notes ?? this.notes,
      familyContact: familyContact ?? this.familyContact,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
