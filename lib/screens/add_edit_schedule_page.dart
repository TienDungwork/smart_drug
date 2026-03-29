import 'package:flutter/material.dart';

import '../models/medicine.dart';
import '../models/medicine_schedule.dart';

class AddEditSchedulePage extends StatefulWidget {
  const AddEditSchedulePage({
    super.key,
    required this.medicines,
    this.existingSchedule,
  });

  final List<Medicine> medicines;
  final MedicineSchedule? existingSchedule;

  @override
  State<AddEditSchedulePage> createState() => _AddEditSchedulePageState();
}

class _AddEditSchedulePageState extends State<AddEditSchedulePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _noteController;

  String? _selectedMedicineId;
  TimeOfDay? _selectedTime;
  bool _isDaily = true;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _noteController =
        TextEditingController(text: widget.existingSchedule?.note ?? '');

    _selectedMedicineId = widget.existingSchedule?.medicineId;
    if (_selectedMedicineId != null &&
        !widget.medicines.any((Medicine e) => e.id == _selectedMedicineId)) {
      _selectedMedicineId =
          widget.medicines.isNotEmpty ? widget.medicines.first.id : null;
    }

    if (widget.existingSchedule != null) {
      _selectedTime = TimeOfDay(
        hour: widget.existingSchedule!.hour,
        minute: widget.existingSchedule!.minute,
      );
      _isDaily = widget.existingSchedule!.isDaily;
      _selectedDate = widget.existingSchedule!.specificDate;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditMode = widget.existingSchedule != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Sửa lịch uống thuốc' : 'Tạo lịch uống thuốc'),
      ),
      body: SafeArea(
        child: widget.medicines.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Chưa có thuốc nào để tạo lịch.\nVui lòng quay lại trang Quản lí thuốc để thêm thuốc trước.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: <Widget>[
                    DropdownButtonFormField<String>(
                      initialValue: _selectedMedicineId,
                      decoration: const InputDecoration(
                        labelText: 'Chọn thuốc *',
                        border: OutlineInputBorder(),
                      ),
                      items: widget.medicines
                          .map(
                            (Medicine medicine) => DropdownMenuItem<String>(
                              value: medicine.id,
                              child: Text(medicine.name),
                            ),
                          )
                          .toList(),
                      onChanged: (String? value) {
                        setState(() {
                          _selectedMedicineId = value;
                        });
                      },
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Bạn phải chọn một thuốc.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue:
                          _isDaily ? MedicineSchedule.typeDaily : MedicineSchedule.typeOnce,
                      decoration: const InputDecoration(
                        labelText: 'Kiểu lịch *',
                        border: OutlineInputBorder(),
                      ),
                      items: const <DropdownMenuItem<String>>[
                        DropdownMenuItem<String>(
                          value: MedicineSchedule.typeDaily,
                          child: Text('Hằng ngày'),
                        ),
                        DropdownMenuItem<String>(
                          value: MedicineSchedule.typeOnce,
                          child: Text('Theo ngày cụ thể'),
                        ),
                      ],
                      onChanged: (String? value) {
                        setState(() {
                          _isDaily = value != MedicineSchedule.typeOnce;
                          if (_isDaily) {
                            _selectedDate = null;
                          }
                        });
                      },
                    ),
                    if (!_isDaily) ...<Widget>[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Text(
                          _selectedDate == null
                              ? 'Chọn ngày uống *'
                              : 'Ngày đã chọn: ${_formatDisplayDate(_selectedDate!)}',
                        ),
                      ),
                      if (_selectedDate == null)
                        const Padding(
                          padding: EdgeInsets.only(top: 6, left: 8),
                          child: Text(
                            'Bạn chưa chọn ngày uống.',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        _selectedTime == null
                            ? 'Chọn giờ uống *'
                            : 'Giờ đã chọn: ${_formatTime(_selectedTime!)}',
                      ),
                    ),
                    if (_selectedTime == null)
                      const Padding(
                        padding: EdgeInsets.only(top: 6, left: 8),
                        child: Text(
                          'Bạn chưa chọn giờ uống.',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú',
                        border: OutlineInputBorder(),
                      ),
                      minLines: 3,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _onSave,
                        child:
                            Text(isEditMode ? 'Cập nhật lịch' : 'Lưu lịch uống thuốc'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = _selectedDate ?? now;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      _selectedDate = pickedDate;
    });
  }

  Future<void> _pickTime() async {
    final TimeOfDay initial = _selectedTime ?? TimeOfDay.now();

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _selectedTime = picked;
    });
  }

  String _formatTime(TimeOfDay time) {
    final String h = time.hour.toString().padLeft(2, '0');
    final String m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDisplayDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  void _onSave() {
    final bool validForm = _formKey.currentState?.validate() ?? false;
    if (!validForm) {
      return;
    }

    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn giờ uống thuốc.')),
      );
      return;
    }

    if (!_isDaily && _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày uống thuốc.')),
      );
      return;
    }

    if (!_isDaily) {
      final DateTime scheduledDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      if (!scheduledDateTime.isAfter(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lịch theo ngày phải có thời gian sau hiện tại.'),
          ),
        );
        return;
      }
    }

    Medicine? selectedMedicine;
    for (final Medicine medicine in widget.medicines) {
      if (medicine.id == _selectedMedicineId) {
        selectedMedicine = medicine;
        break;
      }
    }

    if (selectedMedicine == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy thuốc đã chọn.')),
      );
      return;
    }

    final MedicineSchedule draft = MedicineSchedule(
      id: widget.existingSchedule?.id ?? '',
      medicineId: selectedMedicine.id,
      medicineName: selectedMedicine.name,
      hour: _selectedTime!.hour,
      minute: _selectedTime!.minute,
      scheduleType:
          _isDaily ? MedicineSchedule.typeDaily : MedicineSchedule.typeOnce,
      date: _isDaily ? null : MedicineSchedule.formatDate(_selectedDate!),
      note: _noteController.text.trim(),
      notificationId: widget.existingSchedule?.notificationId ?? 0,
    );

    Navigator.pop(context, draft);
  }
}
