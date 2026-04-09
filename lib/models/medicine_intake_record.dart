class MedicineIntakeRecord {
  final String scheduleId;
  final String dayKey;
  final String takenAt;

  const MedicineIntakeRecord({
    required this.scheduleId,
    required this.dayKey,
    required this.takenAt,
  });

  DateTime? get takenDateTime => DateTime.tryParse(takenAt);

  MedicineIntakeRecord copyWith({
    String? scheduleId,
    String? dayKey,
    String? takenAt,
  }) {
    return MedicineIntakeRecord(
      scheduleId: scheduleId ?? this.scheduleId,
      dayKey: dayKey ?? this.dayKey,
      takenAt: takenAt ?? this.takenAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'scheduleId': scheduleId,
      'dayKey': dayKey,
      'takenAt': takenAt,
    };
  }

  factory MedicineIntakeRecord.fromJson(Map<String, dynamic> json) {
    return MedicineIntakeRecord(
      scheduleId: (json['scheduleId'] ?? '').toString(),
      dayKey: (json['dayKey'] ?? '').toString(),
      takenAt: (json['takenAt'] ?? '').toString(),
    );
  }

  static String buildDayKey(DateTime date) {
    final String year = date.year.toString().padLeft(4, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
