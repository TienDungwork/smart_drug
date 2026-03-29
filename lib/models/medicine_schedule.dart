class MedicineSchedule {
  static const String typeDaily = 'daily';
  static const String typeOnce = 'once';

  final String id;
  final String medicineId;
  final String medicineName;
  final int hour;
  final int minute;
  final String scheduleType;
  final String? date;
  final String note;
  final int notificationId;

  const MedicineSchedule({
    required this.id,
    required this.medicineId,
    required this.medicineName,
    required this.hour,
    required this.minute,
    this.scheduleType = typeDaily,
    this.date,
    this.note = '',
    required this.notificationId,
  });

  bool get isDaily => scheduleType != typeOnce;

  DateTime? get specificDate {
    if (isDaily) {
      return null;
    }
    return parseDate(date);
  }

  MedicineSchedule copyWith({
    String? id,
    String? medicineId,
    String? medicineName,
    int? hour,
    int? minute,
    String? scheduleType,
    String? date,
    bool clearDate = false,
    String? note,
    int? notificationId,
  }) {
    return MedicineSchedule(
      id: id ?? this.id,
      medicineId: medicineId ?? this.medicineId,
      medicineName: medicineName ?? this.medicineName,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      scheduleType: scheduleType ?? this.scheduleType,
      date: clearDate ? null : date ?? this.date,
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
      'scheduleType': scheduleType,
      'date': date,
      'note': note,
      'notificationId': notificationId,
    };
  }

  factory MedicineSchedule.fromJson(Map<String, dynamic> json) {
    final String rawType = (json['scheduleType'] ?? typeDaily).toString();
    final String normalizedType = rawType == typeOnce ? typeOnce : typeDaily;
    final String? rawDate = json['date']?.toString().trim();

    return MedicineSchedule(
      id: (json['id'] ?? '').toString(),
      medicineId: (json['medicineId'] ?? '').toString(),
      medicineName: (json['medicineName'] ?? '').toString(),
      hour: _toInt(json['hour']),
      minute: _toInt(json['minute']),
      scheduleType: normalizedType,
      date: normalizedType == typeOnce ? rawDate : null,
      note: (json['note'] ?? '').toString(),
      notificationId: _toInt(json['notificationId']),
    );
  }

  static DateTime? parseDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final String text = value.trim();
    final List<String> parts = text.split('-');
    if (parts.length != 3) {
      return null;
    }

    final int? year = int.tryParse(parts[0]);
    final int? month = int.tryParse(parts[1]);
    final int? day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      return null;
    }

    try {
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  static String formatDate(DateTime date) {
    final String year = date.year.toString().padLeft(4, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
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
