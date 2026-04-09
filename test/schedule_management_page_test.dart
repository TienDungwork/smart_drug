import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:medicine_reminder_student_app/models/medicine.dart';
import 'package:medicine_reminder_student_app/models/medicine_intake_record.dart';
import 'package:medicine_reminder_student_app/models/medicine_schedule.dart';
import 'package:medicine_reminder_student_app/screens/schedule_management_page.dart';
import 'package:medicine_reminder_student_app/theme/app_theme.dart';

void main() {
  testWidgets('Schedule overview ignores orphan schedules that are not visible', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.buildTheme(),
        home: Scaffold(
          body: ScheduleManagementPage(
            medicines: const <Medicine>[],
            schedules: const <MedicineSchedule>[
              MedicineSchedule(
                id: 'orphan-1',
                medicineId: 'missing-1',
                medicineName: 'Thuoc A',
                hour: 8,
                minute: 0,
                notificationId: 1,
              ),
              MedicineSchedule(
                id: 'orphan-2',
                medicineId: 'missing-2',
                medicineName: 'Thuoc B',
                hour: 20,
                minute: 0,
                notificationId: 2,
              ),
            ],
            intakeRecords: const <MedicineIntakeRecord>[],
            notificationsEnabled: true,
            onSaveSchedule: (_, {oldSchedule}) async {},
            onDeleteSchedule: (_) async {},
            onToggleTakenToday: (_, __) async {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('0/0'), findsOneWidget);
    expect(find.text('Bạn chưa có thuốc nào'), findsOneWidget);
  });
}
