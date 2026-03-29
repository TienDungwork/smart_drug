class MedicineSchedule {
  final String id;
  final String medicineId;
  final String medicineName;
  final int hour;
  final int minute;
  final String note;
  final int notificationId;

  const MedicineSchedule({
    required this.id,
    required this.medicineId,
    required this.medicineName,
    required this.hour,
    required this.minute,
    this.note = '',
    required this.notificationId,
  });

  MedicineSchedule copyWith({
    String? id,
    String? medicineId,
    String? medicineName,
    int? hour,
    int? minute,
    String? note,
    int? notificationId,
  }) {
    return MedicineSchedule(
      id: id ?? this.id,
      medicineId: medicineId ?? this.medicineId,
      medicineName: medicineName ?? this.medicineName,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      note: note ?? this.note,
      notificationId: notificationId ?? this.notificationId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicineId': medicineId,
      'medicineName': medicineName,
      'hour': hour,
      'minute': minute,
      'note': note,
      'notificationId': notificationId,
    };
  }

  factory MedicineSchedule.fromJson(Map<String, dynamic> json) {
    return MedicineSchedule(
      id: (json['id'] ?? '').toString(),
      medicineId: (json['medicineId'] ?? '').toString(),
      medicineName: (json['medicineName'] ?? '').toString(),
      hour: _toInt(json['hour']),
      minute: _toInt(json['minute']),
      note: (json['note'] ?? '').toString(),
      notificationId: _toInt(json['notificationId']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
}
