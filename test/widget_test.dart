import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:medicine_reminder_student_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('App renders redesigned navigation labels', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MedicineReminderApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Tổng quan'), findsWidgets);
    expect(find.text('Tủ thuốc'), findsOneWidget);
    expect(find.text('Tài khoản'), findsOneWidget);
  });
}
