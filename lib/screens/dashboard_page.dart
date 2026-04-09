import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../models/medicine.dart';
import '../models/medicine_intake_record.dart';
import '../models/medicine_schedule.dart';
import '../theme/app_theme.dart';
import '../utils/schedule_utils.dart';

typedef ToggleTakenTodayCallback = Future<void> Function(
  MedicineSchedule schedule,
  bool taken,
);

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.settings,
    required this.medicines,
    required this.schedules,
    required this.intakeRecords,
    required this.onNavigateToTab,
    required this.onToggleTakenToday,
  });

  final AppSettings settings;
  final List<Medicine> medicines;
  final List<MedicineSchedule> schedules;
  final List<MedicineIntakeRecord> intakeRecords;
  final ValueChanged<int> onNavigateToTab;
  final ToggleTakenTodayCallback onToggleTakenToday;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final List<MedicineSchedule> todaySchedules = schedules
        .where((MedicineSchedule schedule) => isScheduleDueOnDate(schedule, now))
        .toList()
      ..sort((MedicineSchedule a, MedicineSchedule b) {
        return scheduleOccurrenceOnDate(a, now)!
            .compareTo(scheduleOccurrenceOnDate(b, now)!);
      });

    final int takenTodayCount = todaySchedules.where((MedicineSchedule schedule) {
      return isScheduleTakenOnDate(schedule, intakeRecords, now);
    }).length;
    final int pendingTodayCount = math.max(0, todaySchedules.length - takenTodayCount);
    final double completionRate = todaySchedules.isEmpty
        ? 0
        : takenTodayCount / todaySchedules.length;

    MedicineSchedule? nextSchedule;
    DateTime? nextOccurrence;
    for (final MedicineSchedule schedule in schedules) {
      final DateTime? candidate = nextPendingOccurrence(
        schedule,
        intakeRecords,
        now: now,
      );
      if (candidate == null) {
        continue;
      }
      if (nextOccurrence == null || candidate.isBefore(nextOccurrence)) {
        nextOccurrence = candidate;
        nextSchedule = schedule;
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: <Widget>[
        _HeroCard(
          displayName: settings.displayName,
          completionRate: completionRate,
          takenTodayCount: takenTodayCount,
          totalTodayCount: todaySchedules.length,
          pendingTodayCount: pendingTodayCount,
          notificationsEnabled: settings.notificationsEnabled,
          nextSchedule: nextSchedule,
          nextOccurrence: nextOccurrence,
          onNavigateToSchedule: () => onNavigateToTab(1),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: _MetricCard(
                title: 'Tủ thuốc',
                value: medicines.length.toString(),
                subtitle: 'Loại đang lưu',
                icon: Icons.medication_rounded,
                colors: const <Color>[
                  Color(0xFFEEF4FF),
                  Color(0xFFD9E7FF),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Chờ uống',
                value: pendingTodayCount.toString(),
                subtitle: 'Lịch còn lại',
                icon: Icons.notifications_active_rounded,
                colors: const <Color>[
                  Color(0xFFFFF2E7),
                  Color(0xFFFFDFC2),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: _MetricCard(
                title: 'Hoàn thành',
                value: todaySchedules.isEmpty
                    ? '0%'
                    : '${(completionRate * 100).round()}%',
                subtitle: 'Tiến độ hôm nay',
                icon: Icons.task_alt_rounded,
                colors: const <Color>[
                  Color(0xFFE9FBF6),
                  Color(0xFFD0F5E9),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Thông báo',
                value: settings.notificationsEnabled ? 'Bật' : 'Tắt',
                subtitle: settings.notificationsEnabled
                    ? 'Đang nhắc đúng giờ'
                    : 'Nên bật để không quên',
                icon: settings.notificationsEnabled
                    ? Icons.notifications_rounded
                    : Icons.notifications_off_rounded,
                colors: const <Color>[
                  Color(0xFFF2EEFF),
                  Color(0xFFE1D7FF),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _SectionCard(
          title: 'Lịch uống hôm nay',
          subtitle: 'Đánh dấu ngay khi bạn đã uống xong.',
          trailing: TextButton(
            onPressed: () => onNavigateToTab(1),
            child: const Text('Mở tab lịch'),
          ),
          child: todaySchedules.isEmpty
              ? const _EmptyState(
                  icon: Icons.event_available_rounded,
                  title: 'Hôm nay chưa có lịch nào',
                  subtitle:
                      'Bạn có thể thêm thuốc hoặc tạo lịch mới để app bắt đầu nhắc nhở.',
                )
              : Column(
                  children: todaySchedules.map((MedicineSchedule schedule) {
                    final bool isTaken =
                        isScheduleTakenOnDate(schedule, intakeRecords, now);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TodayScheduleCard(
                        schedule: schedule,
                        isTaken: isTaken,
                        onToggleTakenToday: onToggleTakenToday,
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.displayName,
    required this.completionRate,
    required this.takenTodayCount,
    required this.totalTodayCount,
    required this.pendingTodayCount,
    required this.notificationsEnabled,
    required this.nextSchedule,
    required this.nextOccurrence,
    required this.onNavigateToSchedule,
  });

  final String displayName;
  final double completionRate;
  final int takenTodayCount;
  final int totalTodayCount;
  final int pendingTodayCount;
  final bool notificationsEnabled;
  final MedicineSchedule? nextSchedule;
  final DateTime? nextOccurrence;
  final VoidCallback onNavigateToSchedule;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF246BFD),
            Color(0xFF35B5FF),
            Color(0xFF52D6B5),
          ],
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x33246BFD),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Xin chào, $displayName',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      totalTodayCount == 0
                          ? 'Hôm nay chưa có lịch uống thuốc nào.'
                          : 'Bạn đã hoàn thành $takenTodayCount/$totalTodayCount lịch uống thuốc hôm nay.',
                      style: const TextStyle(
                        color: Color(0xFFF2F7FF),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Column(
                  children: <Widget>[
                    Text(
                      '${(completionRate * 100).round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'tiến độ',
                      style: TextStyle(
                        color: Color(0xFFE8F1FF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.watch_later_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        nextSchedule == null || nextOccurrence == null
                            ? 'Không còn lịch nào cần uống'
                            : 'Lần nhắc tiếp theo: ${nextSchedule!.medicineName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nextOccurrence == null
                            ? 'Hôm nay bạn đang theo rất tốt.'
                            : '${_buildCountdown(now, nextOccurrence!)} • ${_formatDateTime(nextOccurrence!)}',
                        style: const TextStyle(
                          color: Color(0xFFE7F0FF),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _StatusPill(
                icon: notificationsEnabled
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_off_rounded,
                label: notificationsEnabled ? 'Thông báo đang bật' : 'Thông báo đang tắt',
              ),
              _StatusPill(
                icon: Icons.timelapse_rounded,
                label: '$pendingTodayCount lịch còn lại',
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: onNavigateToSchedule,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primary,
              minimumSize: const Size.fromHeight(52),
            ),
            icon: const Icon(Icons.calendar_month_rounded),
            label: const Text('Xem lịch uống hôm nay'),
          ),
        ],
      ),
    );
  }

  String _buildCountdown(DateTime now, DateTime target) {
    final Duration difference = target.difference(now);
    if (difference.inMinutes <= 0) {
      return 'Đến giờ uống thuốc';
    }
    if (difference.inHours >= 24) {
      return 'Ngày mai';
    }
    if (difference.inHours == 0) {
      return 'Còn ${difference.inMinutes} phút';
    }
    final int minutes = difference.inMinutes.remainder(60);
    if (minutes == 0) {
      return 'Còn ${difference.inHours} giờ';
    }
    return 'Còn ${difference.inHours} giờ $minutes phút';
  }

  String _formatDateTime(DateTime dateTime) {
    final String day = dateTime.day.toString().padLeft(2, '0');
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String time = formatHourMinute(dateTime.hour, dateTime.minute);
    return '$day/$month lúc $time';
  }
}

class _TodayScheduleCard extends StatelessWidget {
  const _TodayScheduleCard({
    required this.schedule,
    required this.isTaken,
    required this.onToggleTakenToday,
  });

  final MedicineSchedule schedule;
  final bool isTaken;
  final ToggleTakenTodayCallback onToggleTakenToday;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final DateTime occurrence = scheduleOccurrenceOnDate(schedule, now)!;
    final bool isLate = !isTaken && occurrence.isBefore(now);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: isTaken ? const Color(0xFFF0FBF7) : Colors.white,
        border: Border.all(
          color: isTaken
              ? const Color(0xFFBDEBD9)
              : const Color(0xFFDCE6FB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isTaken
                      ? const Color(0xFFD8F6EA)
                      : const Color(0xFFE8F0FF),
                ),
                child: Icon(
                  isTaken ? Icons.check_rounded : Icons.medication_rounded,
                  color: isTaken ? AppTheme.secondary : AppTheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      schedule.medicineName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      schedule.note.trim().isEmpty
                          ? 'Nhắc lúc ${formatHourMinute(schedule.hour, schedule.minute)}'
                          : '${formatHourMinute(schedule.hour, schedule.minute)} • ${schedule.note.trim()}',
                      style: const TextStyle(
                        color: Color(0xFF68778F),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              _StateChip(
                label: isTaken
                    ? 'Đã uống'
                    : isLate
                        ? 'Trễ giờ'
                        : 'Sắp tới',
                backgroundColor: isTaken
                    ? const Color(0xFFD9F5E9)
                    : isLate
                        ? const Color(0xFFFFE4C7)
                        : const Color(0xFFE2EBFF),
                foregroundColor: isTaken
                    ? const Color(0xFF167A5B)
                    : isLate
                        ? const Color(0xFFB35D00)
                        : AppTheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => onToggleTakenToday(schedule, !isTaken),
                  style: FilledButton.styleFrom(
                    backgroundColor: isTaken
                        ? const Color(0xFFDFF8ED)
                        : const Color(0xFFEAF1FF),
                    foregroundColor:
                        isTaken ? const Color(0xFF12765A) : AppTheme.primary,
                  ),
                  icon: Icon(
                    isTaken ? Icons.undo_rounded : Icons.task_alt_rounded,
                  ),
                  label: Text(
                    isTaken ? 'Bỏ đánh dấu' : 'Đánh dấu đã uống',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF6A7991),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.colors,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(colors: colors),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 18),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 28,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF5F6F88),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xFFF6F9FF),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, size: 34, color: AppTheme.primary),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF6B7890),
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
