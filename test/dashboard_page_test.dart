import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:medicine_reminder_student_app/models/app_settings.dart';
import 'package:medicine_reminder_student_app/models/medicine.dart';
import 'package:medicine_reminder_student_app/models/medicine_intake_record.dart';
import 'package:medicine_reminder_student_app/models/medicine_schedule.dart';
import 'package:medicine_reminder_student_app/screens/dashboard_page.dart';
import 'package:medicine_reminder_student_app/theme/app_theme.dart';

void main() {
  testWidgets('Dashboard shows adherence state and quick actions', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime.now();
    final MedicineSchedule dailySchedule = MedicineSchedule(
      id: 'schedule-1',
      medicineId: 'medicine-1',
      medicineName: 'Vitamin C',
      hour: now.hour,
      minute: now.minute,
      notificationId: 10,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.buildTheme(),
        home: DashboardPage(
          settings: AppSettings.initial(),
          medicines: const <Medicine>[
            Medicine(id: 'medicine-1', name: 'Vitamin C'),
          ],
          schedules: <MedicineSchedule>[dailySchedule],
          intakeRecords: <MedicineIntakeRecord>[
            MedicineIntakeRecord(
              scheduleId: dailySchedule.id,
              dayKey: MedicineIntakeRecord.buildDayKey(now),
              takenAt: now.toIso8601String(),
            ),
          ],
          onNavigateToTab: (_) {},
          onToggleTakenToday: (_, __) async {},
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Lịch uống hôm nay'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Lịch uống hôm nay'), findsOneWidget);
    expect(find.text('Đã uống'), findsWidgets);
    expect(find.text('Mẹo an toàn'), findsNothing);
    expect(find.text('Gợi ý hôm nay'), findsNothing);
    expect(find.text('Vitamin C'), findsWidgets);
  });
}
