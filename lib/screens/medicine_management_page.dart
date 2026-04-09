import 'package:flutter/material.dart';

import '../models/medicine.dart';
import '../models/medicine_schedule.dart';
import '../theme/app_theme.dart';
import 'add_edit_medicine_page.dart';

typedef SaveMedicineCallback = Future<void> Function(
  Medicine draft, {
  Medicine? oldMedicine,
});

typedef DeleteMedicineCallback = Future<bool> Function(Medicine medicine);

class MedicineManagementPage extends StatelessWidget {
  const MedicineManagementPage({
    super.key,
    required this.medicines,
    required this.schedules,
    required this.onSaveMedicine,
    required this.onDeleteMedicine,
  });

  final List<Medicine> medicines;
  final List<MedicineSchedule> schedules;
  final SaveMedicineCallback onSaveMedicine;
  final DeleteMedicineCallback onDeleteMedicine;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _MedicineOverviewCard(
            medicineCount: medicines.length,
            activeScheduleCount: schedules.length,
            onAddMedicine: () => _openAddMedicine(context),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: medicines.isEmpty
                ? const _EmptyMedicineState()
                : ListView.separated(
                    itemCount: medicines.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (BuildContext context, int index) {
                      final Medicine medicine = medicines[index];
                      final int usedCount = schedules
                          .where((MedicineSchedule e) => e.medicineId == medicine.id)
                          .length;

                      return _MedicineCard(
                        medicine: medicine,
                        usedCount: usedCount,
                        onEdit: () => _openEditMedicine(context, medicine),
                        onDelete: () =>
                            _onTapDelete(context, medicine, usedCount),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddMedicine(BuildContext context) async {
    final Medicine? draft = await Navigator.push<Medicine>(
      context,
      MaterialPageRoute<Medicine>(
        builder: (_) => const AddEditMedicinePage(),
      ),
    );

    if (draft == null) {
      return;
    }

    await onSaveMedicine(draft);
  }

  Future<void> _openEditMedicine(BuildContext context, Medicine medicine) async {
    final Medicine? draft = await Navigator.push<Medicine>(
      context,
      MaterialPageRoute<Medicine>(
        builder: (_) => AddEditMedicinePage(existingMedicine: medicine),
      ),
    );

    if (draft == null) {
      return;
    }

    await onSaveMedicine(draft, oldMedicine: medicine);
  }

  Future<void> _onTapDelete(
    BuildContext context,
    Medicine medicine,
    int usedCount,
  ) async {
    if (usedCount > 0) {
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Không thể xóa thuốc'),
            content: const Text(
              'Thuốc này đang được sử dụng trong lịch uống thuốc.\nHãy xóa các lịch liên quan trước.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          );
        },
      );
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text('Bạn có chắc chắn muốn xóa thuốc "${medicine.name}" không?'),
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

    await onDeleteMedicine(medicine);
  }
}

class _MedicineOverviewCard extends StatelessWidget {
  const _MedicineOverviewCard({
    required this.medicineCount,
    required this.activeScheduleCount,
    required this.onAddMedicine,
  });

  final int medicineCount;
  final int activeScheduleCount;
  final VoidCallback onAddMedicine;

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
            Color(0xFFEAFBF6),
            Color(0xFFF7FFFD),
          ],
        ),
        border: Border.all(color: const Color(0xFFD4F0E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Tủ thuốc của bạn',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Đang lưu $medicineCount thuốc và $activeScheduleCount lịch hoạt động.',
            style: const TextStyle(
              color: Color(0xFF607088),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAddMedicine,
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: const Text('Thêm thuốc'),
          ),
        ],
      ),
    );
  }
}

class _MedicineCard extends StatelessWidget {
  const _MedicineCard({
    required this.medicine,
    required this.usedCount,
    required this.onEdit,
    required this.onDelete,
  });

  final Medicine medicine;
  final int usedCount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
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
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE6FBF4),
                  ),
                  child: const Icon(
                    Icons.medication_liquid_rounded,
                    color: AppTheme.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        medicine.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        medicine.note.trim().isEmpty
                            ? 'Chưa có ghi chú thêm cho thuốc này.'
                            : medicine.note.trim(),
                        style: const TextStyle(
                          color: Color(0xFF66758E),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$usedCount lịch',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _MedicineChip(
                  icon: Icons.science_outlined,
                  label: medicine.dosage.trim().isEmpty
                      ? 'Chưa có liều lượng'
                      : 'Liều: ${medicine.dosage.trim()}',
                ),
                _MedicineChip(
                  icon: Icons.inventory_2_outlined,
                  label: usedCount == 0
                      ? 'Chưa gắn vào lịch'
                      : 'Đang dùng trong $usedCount lịch',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Sửa thuốc'),
                  ),
                ),
                const SizedBox(width: 10),
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
}

class _MedicineChip extends StatelessWidget {
  const _MedicineChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF53627C),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMedicineState extends StatelessWidget {
  const _EmptyMedicineState();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.medication_outlined,
                size: 44,
                color: AppTheme.primary,
              ),
              const SizedBox(height: 14),
              Text(
                'Danh sách thuốc đang trống',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Hãy thêm thuốc mới để tạo lịch uống, theo dõi và nhắc nhở đúng giờ.',
                style: TextStyle(
                  color: Color(0xFF66758E),
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
