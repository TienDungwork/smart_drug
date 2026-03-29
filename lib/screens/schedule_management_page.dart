import 'package:flutter/material.dart';

import '../models/medicine.dart';
import '../models/medicine_schedule.dart';
import 'add_edit_schedule_page.dart';

typedef SaveScheduleCallback = Future<void> Function(
  MedicineSchedule draft, {
  MedicineSchedule? oldSchedule,
});

typedef DeleteScheduleCallback = Future<void> Function(MedicineSchedule schedule);

class ScheduleManagementPage extends StatelessWidget {
  const ScheduleManagementPage({
    super.key,
    required this.medicines,
    required this.schedules,
    required this.notificationsEnabled,
    required this.onSaveSchedule,
    required this.onDeleteSchedule,
  });

  final List<Medicine> medicines;
  final List<MedicineSchedule> schedules;
  final bool notificationsEnabled;
  final SaveScheduleCallback onSaveSchedule;
  final DeleteScheduleCallback onDeleteSchedule;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!notificationsEnabled)
            const Card(
              color: Color(0xFFFFF8E1),
              child: ListTile(
                leading: Icon(Icons.notifications_off),
                title: Text('Thông báo đang tắt'),
                subtitle: Text(
                  'Lịch vẫn được lưu nhưng sẽ không gửi nhắc cho đến khi bạn bật lại thông báo trong trang Tài khoản.',
                ),
              ),
            ),
          if (!notificationsEnabled) const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _openAddSchedule(context),
              icon: const Icon(Icons.add_alarm),
              label: const Text('Tạo lịch uống thuốc'),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _buildScheduleContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleContent(BuildContext context) {
    if (medicines.isEmpty) {
      return const Card(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Bạn chưa có thuốc nào.\nVui lòng thêm thuốc trước khi tạo lịch uống thuốc.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (schedules.isEmpty) {
      return const Card(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Chưa có lịch uống thuốc nào.\nNhấn "Tạo lịch uống thuốc" để bắt đầu.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: schedules.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int index) {
        final MedicineSchedule schedule = schedules[index];

        return Card(
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.alarm),
            ),
            title: Text(schedule.medicineName),
            subtitle: Text(_buildSubtitle(schedule)),
            trailing: Wrap(
              spacing: 4,
              children: <Widget>[
                IconButton(
                  tooltip: 'Sửa',
                  onPressed: () => _openEditSchedule(context, schedule),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Xóa',
                  onPressed: () => _onTapDelete(context, schedule),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _buildSubtitle(MedicineSchedule schedule) {
    final String scheduleText = _buildScheduleText(schedule);
    final String noteText = schedule.note.trim().isEmpty
        ? 'Không có ghi chú'
        : 'Ghi chú: ${schedule.note.trim()}';

    return '$scheduleText\n$noteText';
  }

  String _formatTime(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String _buildScheduleText(MedicineSchedule schedule) {
    final String timeText = _formatTime(schedule.hour, schedule.minute);

    if (schedule.isDaily) {
      return 'Lặp: Hằng ngày lúc $timeText';
    }

    final DateTime? date = schedule.specificDate;
    if (date == null) {
      return 'Theo ngày: Không hợp lệ';
    }

    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return 'Ngày uống: $day/$month/${date.year} lúc $timeText';
  }

  Future<void> _openAddSchedule(BuildContext context) async {
    if (medicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa có thuốc. Hãy tạo thuốc trước khi lập lịch.'),
        ),
      );
      return;
    }

    final MedicineSchedule? draft = await Navigator.push<MedicineSchedule>(
      context,
      MaterialPageRoute<MedicineSchedule>(
        builder: (_) => AddEditSchedulePage(medicines: medicines),
      ),
    );

    if (draft == null) {
      return;
    }

    await onSaveSchedule(draft);
  }

  Future<void> _openEditSchedule(
    BuildContext context,
    MedicineSchedule schedule,
  ) async {
    final MedicineSchedule? draft = await Navigator.push<MedicineSchedule>(
      context,
      MaterialPageRoute<MedicineSchedule>(
        builder: (_) => AddEditSchedulePage(
          medicines: medicines,
          existingSchedule: schedule,
        ),
      ),
    );

    if (draft == null) {
      return;
    }

    await onSaveSchedule(draft, oldSchedule: schedule);
  }

  Future<void> _onTapDelete(
    BuildContext context,
    MedicineSchedule schedule,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa lịch'),
          content: Text(
            'Bạn có chắc chắn muốn xóa lịch ${schedule.medicineName} (${_buildScheduleText(schedule)}) không?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await onDeleteSchedule(schedule);
  }
}
