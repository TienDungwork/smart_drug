import 'package:flutter/material.dart';

import '../models/medicine.dart';
import '../models/medicine_schedule.dart';
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _openAddMedicine(context),
              icon: const Icon(Icons.add),
              label: const Text('Thêm thuốc'),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: medicines.isEmpty
                ? const Card(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Danh sách thuốc đang rỗng.\nHãy thêm thuốc mới để tạo lịch uống thuốc.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: medicines.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (BuildContext context, int index) {
                      final Medicine medicine = medicines[index];
                      final int usedCount = schedules
                          .where((MedicineSchedule e) => e.medicineId == medicine.id)
                          .length;

                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.medication),
                          ),
                          title: Text(medicine.name),
                          subtitle: _buildSubtitle(medicine, usedCount),
                          trailing: Wrap(
                            spacing: 4,
                            children: <Widget>[
                              IconButton(
                                tooltip: 'Sửa',
                                onPressed: () => _openEditMedicine(context, medicine),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                tooltip: 'Xóa',
                                onPressed: () => _onTapDelete(context, medicine, usedCount),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle(Medicine medicine, int usedCount) {
    final List<String> lines = <String>[];

    if (medicine.dosage.trim().isNotEmpty) {
      lines.add('Liều lượng: ${medicine.dosage.trim()}');
    }
    if (medicine.note.trim().isNotEmpty) {
      lines.add('Ghi chú: ${medicine.note.trim()}');
    }

    lines.add('Đang được dùng trong $usedCount lịch.');

    return Text(lines.join('\n'));
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
