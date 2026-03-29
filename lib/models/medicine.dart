class Medicine {
  final String id;
  final String name;
  final String dosage;
  final String note;

  const Medicine({
    required this.id,
    required this.name,
    this.dosage = '',
    this.note = '',
  });

  Medicine copyWith({
    String? id,
    String? name,
    String? dosage,
    String? note,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'note': note,
    };
  }

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      dosage: (json['dosage'] ?? '').toString(),
      note: (json['note'] ?? '').toString(),
    );
  }
}
