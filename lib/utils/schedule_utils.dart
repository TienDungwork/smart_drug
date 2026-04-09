import '../models/medicine_intake_record.dart';
import '../models/medicine_schedule.dart';

bool isSameDay(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

bool isScheduleDueOnDate(MedicineSchedule schedule, DateTime date) {
  if (schedule.isDaily) {
    return true;
  }

  final DateTime? specificDate = schedule.specificDate;
  if (specificDate == null) {
    return false;
  }

  return isSameDay(specificDate, date);
}

DateTime? scheduleOccurrenceOnDate(
  MedicineSchedule schedule,
  DateTime date,
) {
  if (!isScheduleDueOnDate(schedule, date)) {
    return null;
  }

  return DateTime(
    date.year,
    date.month,
    date.day,
    schedule.hour,
    schedule.minute,
  );
}

bool isScheduleTakenOnDate(
  MedicineSchedule schedule,
  List<MedicineIntakeRecord> records,
  DateTime date,
) {
  final String dayKey = MedicineIntakeRecord.buildDayKey(date);
  return records.any((MedicineIntakeRecord record) {
    return record.scheduleId == schedule.id && record.dayKey == dayKey;
  });
}

DateTime? nextPendingOccurrence(
  MedicineSchedule schedule,
  List<MedicineIntakeRecord> records, {
  DateTime? now,
}) {
  final DateTime current = now ?? DateTime.now();

  if (schedule.isDaily) {
    final DateTime todayOccurrence = DateTime(
      current.year,
      current.month,
      current.day,
      schedule.hour,
      schedule.minute,
    );
    final bool takenToday = isScheduleTakenOnDate(schedule, records, current);

    if (!takenToday && todayOccurrence.isAfter(current)) {
      return todayOccurrence;
    }

    return todayOccurrence.add(const Duration(days: 1));
  }

  final DateTime? specificDate = schedule.specificDate;
  if (specificDate == null) {
    return null;
  }

  final DateTime occurrence = DateTime(
    specificDate.year,
    specificDate.month,
    specificDate.day,
    schedule.hour,
    schedule.minute,
  );

  if (!occurrence.isAfter(current)) {
    return null;
  }

  if (isScheduleTakenOnDate(schedule, records, occurrence)) {
    return null;
  }

  return occurrence;
}

String formatHourMinute(int hour, int minute) {
  final String h = hour.toString().padLeft(2, '0');
  final String m = minute.toString().padLeft(2, '0');
  return '$h:$m';
}
