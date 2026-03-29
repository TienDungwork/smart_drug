import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/medicine.dart';

class AddEditMedicinePage extends StatefulWidget {
  const AddEditMedicinePage({
    super.key,
    this.existingMedicine,
  });

  final Medicine? existingMedicine;

  @override
  State<AddEditMedicinePage> createState() => _AddEditMedicinePageState();
}

class _AddEditMedicinePageState extends State<AddEditMedicinePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _dosageController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.existingMedicine?.name ?? '');
    _dosageController =
        TextEditingController(text: widget.existingMedicine?.dosage ?? '');
    _noteController =
        TextEditingController(text: widget.existingMedicine?.note ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditMode = widget.existingMedicine != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Sửa thuốc' : 'Thêm thuốc'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên thuốc *',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                validator: (String? value) {
                  final String text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return 'Tên thuốc không được để trống.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(
                  labelText: 'Liều lượng',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                textInputAction: TextInputAction.next,
                validator: (String? value) {
                  final String text = value?.trim() ?? '';
                  if (text.isNotEmpty && !RegExp(r'^\d+$').hasMatch(text)) {
                    return 'Liều lượng chỉ được nhập số.';
                  }
                  return null;
                },
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
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _onSave,
                  child: Text(isEditMode ? 'Cập nhật' : 'Lưu thuốc'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final Medicine draft = Medicine(
      id: widget.existingMedicine?.id ?? '',
      name: _nameController.text.trim(),
      dosage: _dosageController.text.trim(),
      note: _noteController.text.trim(),
    );

    Navigator.pop(context, draft);
  }
}
