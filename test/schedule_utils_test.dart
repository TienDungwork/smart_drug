import 'package:flutter_test/flutter_test.dart';

import 'package:medicine_reminder_student_app/models/medicine_intake_record.dart';
import 'package:medicine_reminder_student_app/models/medicine_schedule.dart';
import 'package:medicine_reminder_student_app/utils/schedule_utils.dart';

void main() {
  test('isScheduleTakenOnDate returns true for matching daily intake record', () {
    final DateTime now = DateTime.now();
    const MedicineSchedule schedule = MedicineSchedule(
      id: 'schedule-1',
      medicineId: 'medicine-1',
      medicineName: 'Omega 3',
      hour: 8,
      minute: 30,
      notificationId: 101,
    );

    final List<MedicineIntakeRecord> records = <MedicineIntakeRecord>[
      MedicineIntakeRecord(
        scheduleId: schedule.id,
        dayKey: MedicineIntakeRecord.buildDayKey(now),
        takenAt: now.toIso8601String(),
      ),
    ];

    expect(isScheduleTakenOnDate(schedule, records, now), isTrue);
  });

  test('nextPendingOccurrence moves to tomorrow when daily schedule is already taken', () {
    final DateTime now = DateTime.now();
    final MedicineSchedule schedule = MedicineSchedule(
      id: 'schedule-2',
      medicineId: 'medicine-2',
      medicineName: 'Calcium',
      hour: now.hour,
      minute: now.minute,
      notificationId: 102,
    );

    final List<MedicineIntakeRecord> records = <MedicineIntakeRecord>[
      MedicineIntakeRecord(
        scheduleId: schedule.id,
        dayKey: MedicineIntakeRecord.buildDayKey(now),
        takenAt: now.toIso8601String(),
      ),
    ];

    final DateTime? nextOccurrence = nextPendingOccurrence(
      schedule,
      records,
      now: now,
    );

    expect(nextOccurrence, isNotNull);
    expect(nextOccurrence!.day, isNot(now.day));
  });
}
