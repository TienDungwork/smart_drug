import 'package:flutter_test/flutter_test.dart';

import 'package:medicine_reminder_student_app/main.dart';

void main() {
  testWidgets('App renders main navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const MedicineReminderApp());
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
  });
}
