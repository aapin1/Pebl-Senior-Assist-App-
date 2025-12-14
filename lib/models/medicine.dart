/// Model class for storing medicine information
/// Represents a single medication with essential details only
class Medicine {
  final String id;
  final String name;
  final String dosage;
  final List<String> timesToTake;
  final String? notes;
  final DateTime createdAt;

  // Map of time label (e.g. "Morning") to exact time string in HH:mm format
  final Map<String, String> timesToTakeDetails;

  // Whether local reminder notifications are enabled for this medicine
  final bool remindersEnabled;

  Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    required this.timesToTake,
    this.notes,
    required this.createdAt,
    Map<String, String>? timesToTakeDetails,
    bool remindersEnabled = false,
  })  : timesToTakeDetails = timesToTakeDetails ?? const {},
        remindersEnabled = remindersEnabled;

  /// Convert Medicine object to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'timesToTake': timesToTake,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'timesToTakeDetails': timesToTakeDetails,
      'remindersEnabled': remindersEnabled,
    };
  }

  /// Create Medicine object from JSON
  factory Medicine.fromJson(Map<String, dynamic> json) {
    final rawTimesToTake = json['timesToTake'];
    final List<String> parsedTimesToTake = rawTimesToTake is List
        ? List<String>.from(rawTimesToTake)
        : <String>[];

    final rawDetails = json['timesToTakeDetails'];
    final Map<String, String> parsedDetails = rawDetails is Map
        ? rawDetails.map((key, value) => MapEntry(key as String, value as String))
        : <String, String>{};

    return Medicine(
      id: json['id'] as String,
      name: json['name'] as String,
      dosage: json['dosage'] as String,
      timesToTake: parsedTimesToTake,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      timesToTakeDetails: parsedDetails,
      remindersEnabled: json['remindersEnabled'] as bool? ?? false,
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
    Map<String, String>? timesToTakeDetails,
    bool? remindersEnabled,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      timesToTake: timesToTake ?? this.timesToTake,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      timesToTakeDetails: timesToTakeDetails ?? this.timesToTakeDetails,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
    );
  }
}
