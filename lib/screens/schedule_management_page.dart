import 'package:flutter/material.dart';

import '../models/medicine.dart';
import '../models/medicine_intake_record.dart';
import '../models/medicine_schedule.dart';
import '../theme/app_theme.dart';
import '../utils/schedule_utils.dart';
import 'add_edit_schedule_page.dart';

typedef SaveScheduleCallback = Future<void> Function(
  MedicineSchedule draft, {
  MedicineSchedule? oldSchedule,
});

typedef DeleteScheduleCallback = Future<void> Function(MedicineSchedule schedule);
typedef ToggleTakenTodayCallback = Future<void> Function(
  MedicineSchedule schedule,
  bool taken,
);

class ScheduleManagementPage extends StatelessWidget {
  const ScheduleManagementPage({
    super.key,
    required this.medicines,
    required this.schedules,
    required this.intakeRecords,
    required this.notificationsEnabled,
    required this.onSaveSchedule,
    required this.onDeleteSchedule,
    required this.onToggleTakenToday,
  });

  final List<Medicine> medicines;
  final List<MedicineSchedule> schedules;
  final List<MedicineIntakeRecord> intakeRecords;
  final bool notificationsEnabled;
  final SaveScheduleCallback onSaveSchedule;
  final DeleteScheduleCallback onDeleteSchedule;
  final ToggleTakenTodayCallback onToggleTakenToday;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final List<MedicineSchedule> visibleSchedules = _visibleSchedules();
    final int dueTodayCount = visibleSchedules
        .where((MedicineSchedule schedule) => isScheduleDueOnDate(schedule, now))
        .length;
    final int takenTodayCount = visibleSchedules.where((MedicineSchedule schedule) {
      return isScheduleDueOnDate(schedule, now) &&
          isScheduleTakenOnDate(schedule, intakeRecords, now);
    }).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _ScheduleOverviewCard(
            dueTodayCount: dueTodayCount,
            takenTodayCount: takenTodayCount,
            notificationsEnabled: notificationsEnabled,
            onCreateSchedule: () => _openAddSchedule(context),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _buildScheduleContent(context, visibleSchedules),
          ),
        ],
      ),
    );
  }

  List<MedicineSchedule> _visibleSchedules() {
    final Set<String> validMedicineIds =
        medicines.map((Medicine medicine) => medicine.id).toSet();

    return schedules.where((MedicineSchedule schedule) {
      if (validMedicineIds.isEmpty) {
        return false;
      }
      return validMedicineIds.contains(schedule.medicineId);
    }).toList();
  }

  Widget _buildScheduleContent(
    BuildContext context,
    List<MedicineSchedule> visibleSchedules,
  ) {
    if (medicines.isEmpty) {
      return const _EmptyPanel(
        icon: Icons.medication_outlined,
        title: 'Bạn chưa có thuốc nào',
        subtitle:
            'Hãy thêm thuốc trước, sau đó quay lại đây để tạo lịch nhắc uống.',
      );
    }

    if (visibleSchedules.isEmpty) {
      return const _EmptyPanel(
        icon: Icons.add_alarm_rounded,
        title: 'Chưa có lịch uống thuốc',
        subtitle:
            'Nhấn "Tạo lịch uống thuốc" để bắt đầu xây dựng kế hoạch dùng thuốc mỗi ngày.',
      );
    }

    final DateTime now = DateTime.now();

    return ListView.separated(
      itemCount: visibleSchedules.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        final MedicineSchedule schedule = visibleSchedules[index];
        final bool isDueToday = isScheduleDueOnDate(schedule, now);
        final bool isTakenToday =
            isDueToday && isScheduleTakenOnDate(schedule, intakeRecords, now);
        final DateTime? nextOccurrence = nextPendingOccurrence(
          schedule,
          intakeRecords,
          now: now,
        );

        return _ScheduleCard(
          schedule: schedule,
          isDueToday: isDueToday,
          isTakenToday: isTakenToday,
          nextOccurrence: nextOccurrence,
          onEdit: () => _openEditSchedule(context, schedule),
          onDelete: () => _onTapDelete(context, schedule),
          onToggleTakenToday: isDueToday
              ? () => onToggleTakenToday(schedule, !isTakenToday)
              : null,
        );
      },
    );
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

  String _buildScheduleText(MedicineSchedule schedule) {
    final String timeText = formatHourMinute(schedule.hour, schedule.minute);
    if (schedule.isDaily) {
      return 'Hằng ngày lúc $timeText';
    }

    final DateTime? date = schedule.specificDate;
    if (date == null) {
      return 'Theo ngày: Không hợp lệ';
    }

    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year} lúc $timeText';
  }
}

class _ScheduleOverviewCard extends StatelessWidget {
  const _ScheduleOverviewCard({
    required this.dueTodayCount,
    required this.takenTodayCount,
    required this.notificationsEnabled,
    required this.onCreateSchedule,
  });

  final int dueTodayCount;
  final int takenTodayCount;
  final bool notificationsEnabled;
  final VoidCallback onCreateSchedule;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFEEF5FF),
            Color(0xFFF8FBFF),
          ],
        ),
        border: Border.all(color: const Color(0xFFD8E4FA)),
      ),
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
                      'Lịch nhắc uống thuốc',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notificationsEnabled
                          ? 'Bạn đang theo dõi $dueTodayCount lịch trong hôm nay.'
                          : 'Thông báo đang tắt. Lịch vẫn được lưu nhưng sẽ không nhắc tự động.',
                      style: const TextStyle(
                        color: Color(0xFF64738C),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: dueTodayCount == 0
                      ? const Color(0xFFEAF1FF)
                      : const Color(0xFFD9F6EC),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  '$takenTodayCount/$dueTodayCount',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onCreateSchedule,
            icon: const Icon(Icons.add_alarm_rounded),
            label: const Text('Tạo lịch uống thuốc'),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.schedule,
    required this.isDueToday,
    required this.isTakenToday,
    required this.nextOccurrence,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleTakenToday,
  });

  final MedicineSchedule schedule;
  final bool isDueToday;
  final bool isTakenToday;
  final DateTime? nextOccurrence;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onToggleTakenToday;

  @override
  Widget build(BuildContext context) {
    final bool isExpiredOneTime =
        !schedule.isDaily && schedule.specificDate != null && nextOccurrence == null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isTakenToday
                        ? const Color(0xFFD7F7EA)
                        : const Color(0xFFE7EEFF),
                  ),
                  child: Icon(
                    isTakenToday ? Icons.task_alt_rounded : Icons.alarm_rounded,
                    color: isTakenToday ? AppTheme.secondary : AppTheme.primary,
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
                      const SizedBox(height: 6),
                      Text(
                        _buildSubtitle(),
                        style: const TextStyle(
                          color: Color(0xFF66758E),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(
                  label: isTakenToday
                      ? 'Đã uống'
                      : isExpiredOneTime
                          ? 'Đã qua'
                          : isDueToday
                              ? 'Hôm nay'
                              : 'Sắp tới',
                  backgroundColor: isTakenToday
                      ? const Color(0xFFD8F6E8)
                      : isExpiredOneTime
                          ? const Color(0xFFFFE2DE)
                          : isDueToday
                              ? const Color(0xFFE3EBFF)
                              : const Color(0xFFFFEED9),
                  foregroundColor: isTakenToday
                      ? const Color(0xFF147559)
                      : isExpiredOneTime
                          ? const Color(0xFFB25140)
                          : isDueToday
                              ? AppTheme.primary
                              : const Color(0xFFB06D13),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _InfoChip(
                  icon: schedule.isDaily
                      ? Icons.repeat_rounded
                      : Icons.calendar_month_rounded,
                  label: schedule.isDaily ? 'Lặp hằng ngày' : 'Theo ngày cụ thể',
                ),
                _InfoChip(
                  icon: Icons.access_time_rounded,
                  label: formatHourMinute(schedule.hour, schedule.minute),
                ),
                if (schedule.note.trim().isNotEmpty)
                  _InfoChip(
                    icon: Icons.sticky_note_2_rounded,
                    label: schedule.note.trim(),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                if (onToggleTakenToday != null)
                  FilledButton.tonalIcon(
                    onPressed: onToggleTakenToday,
                    style: FilledButton.styleFrom(
                      backgroundColor: isTakenToday
                          ? const Color(0xFFDDF8EC)
                          : const Color(0xFFEAF1FF),
                      foregroundColor:
                          isTakenToday ? const Color(0xFF14795D) : AppTheme.primary,
                    ),
                    icon: Icon(
                      isTakenToday ? Icons.undo_rounded : Icons.check_circle_rounded,
                    ),
                    label: Text(
                      isTakenToday ? 'Bỏ đánh dấu' : 'Đã uống hôm nay',
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Sửa'),
                ),
                IconButton(
                  tooltip: 'Xóa',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _buildSubtitle() {
    final DateTime? occurrence = nextOccurrence;

    if (isDueToday) {
      return isTakenToday
          ? 'Bạn đã xác nhận uống thuốc cho lịch này trong hôm nay.'
          : 'Đây là lịch áp dụng cho hôm nay. Hãy đánh dấu ngay sau khi uống.';
    }

    if (occurrence != null) {
      final String day = occurrence.day.toString().padLeft(2, '0');
      final String month = occurrence.month.toString().padLeft(2, '0');
      return 'Lần nhắc tiếp theo vào $day/$month lúc ${formatHourMinute(occurrence.hour, occurrence.minute)}.';
    }

    return 'Lịch theo ngày này đã qua hoặc không còn thời điểm nhắc hợp lệ.';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FE),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 16, color: AppTheme.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF53627C),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 42, color: AppTheme.primary),
              const SizedBox(height: 14),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF67758C),
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
