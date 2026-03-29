import 'package:flutter/material.dart';

import '../models/medicine.dart';
import '../models/medicine_schedule.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.medicines,
    required this.schedules,
  });

  final List<Medicine> medicines;
  final List<MedicineSchedule> schedules;

  @override
  Widget build(BuildContext context) {
    final int todaySchedulesCount =
        schedules.where((MedicineSchedule schedule) => _isTodaySchedule(schedule)).length;

    final List<MedicineSchedule> upcomingSchedules = schedules
        .where((MedicineSchedule schedule) => _nextOccurrence(schedule) != null)
        .toList()
      ..sort((MedicineSchedule a, MedicineSchedule b) {
        return _nextOccurrence(a)!.compareTo(_nextOccurrence(b)!);
      });

    final List<MedicineSchedule> topSchedules = upcomingSchedules.take(5).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _SummaryCard(
                  icon: Icons.medication,
                  title: 'Tổng số thuốc',
                  value: medicines.length.toString(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.schedule,
                  title: 'Tổng số lịch',
                  value: schedules.length.toString(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SummaryCard(
            icon: Icons.today,
            title: 'Lịch trong ngày',
            value: todaySchedulesCount.toString(),
          ),
          const SizedBox(height: 20),
          Text(
            'Lịch sắp tới',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (topSchedules.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Chưa có lịch uống thuốc nào.'),
              ),
            )
          else
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: topSchedules.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (BuildContext context, int index) {
                  final MedicineSchedule schedule = topSchedules[index];
                  final DateTime? nextTime = _nextOccurrence(schedule);
                  if (nextTime == null) {
                    return const SizedBox.shrink();
                  }
                  return ListTile(
                    leading: const Icon(Icons.alarm),
                    title: Text(schedule.medicineName),
                    subtitle: Text(
                      _buildScheduleText(schedule, nextTime),
                    ),
                    trailing: schedule.note.trim().isEmpty
                        ? null
                        : const Icon(Icons.notes, size: 18),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  String _buildScheduleText(MedicineSchedule schedule, DateTime nextTime) {
    final String timeText = _formatTime(schedule.hour, schedule.minute);
    if (schedule.isDaily) {
      return 'Hằng ngày lúc $timeText - lần tới: ${_formatDateTime(nextTime)}';
    }
    return 'Theo ngày lúc $timeText - ${_formatDateTime(nextTime)}';
  }

  bool _isTodaySchedule(MedicineSchedule schedule) {
    if (schedule.isDaily) {
      return true;
    }

    final DateTime? specificDate = schedule.specificDate;
    if (specificDate == null) {
      return false;
    }

    final DateTime now = DateTime.now();
    return now.year == specificDate.year &&
        now.month == specificDate.month &&
        now.day == specificDate.day;
  }

  DateTime? _nextOccurrence(MedicineSchedule schedule) {
    final DateTime now = DateTime.now();
    if (schedule.isDaily) {
      DateTime dateTime = DateTime(
        now.year,
        now.month,
        now.day,
        schedule.hour,
        schedule.minute,
      );

      if (!dateTime.isAfter(now)) {
        dateTime = dateTime.add(const Duration(days: 1));
      }
      return dateTime;
    }

    final DateTime? specificDate = schedule.specificDate;
    if (specificDate == null) {
      return null;
    }

    final DateTime dateTime = DateTime(
      specificDate.year,
      specificDate.month,
      specificDate.day,
      schedule.hour,
      schedule.minute,
    );

    if (!dateTime.isAfter(now)) {
      return null;
    }

    return dateTime;
  }

  String _formatTime(int hour, int minute) {
    final String h = hour.toString().padLeft(2, '0');
    final String m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDateTime(DateTime dateTime) {
    final String day = dateTime.day.toString().padLeft(2, '0');
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String year = dateTime.year.toString();
    final String time = _formatTime(dateTime.hour, dateTime.minute);
    return '$day/$month/$year $time';
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: 28),
            const SizedBox(height: 10),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
