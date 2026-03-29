import 'package:flutter/material.dart';

import '../models/app_settings.dart';

typedef UpdateDisplayNameCallback = Future<void> Function(String displayName);
typedef ToggleNotificationsCallback = Future<void> Function(bool enabled);

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({
    super.key,
    required this.settings,
    required this.onUpdateDisplayName,
    required this.onToggleNotifications,
  });

  final AppSettings settings;
  final UpdateDisplayNameCallback onUpdateDisplayName;
  final ToggleNotificationsCallback onToggleNotifications;

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  bool _isUpdatingNotifications = false;
  bool _isUpdatingDisplayName = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Thông tin tài khoản',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    const CircleAvatar(
                      radius: 28,
                      child: Icon(Icons.person, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            widget.settings.displayName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(widget.settings.email),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _isUpdatingDisplayName
                        ? null
                        : _showEditNameDialog,
                    icon: const Icon(Icons.edit),
                    label: const Text('Sửa tên hiển thị'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  'Cấu hình hệ thống',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              SwitchListTile(
                value: widget.settings.notificationsEnabled,
                title: const Text('Bật thông báo nhắc uống thuốc'),
                subtitle: const Text(
                  'Nếu tắt, app vẫn lưu lịch nhưng không tạo thông báo mới và hủy các thông báo đã lập.',
                ),
                onChanged: _isUpdatingNotifications
                    ? null
                    : (bool value) => _onToggleNotifications(value),
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Phiên bản ứng dụng'),
                subtitle: Text('1.0.0'),
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(Icons.description_outlined),
                title: Text('Giới thiệu ngắn'),
                subtitle: Text(
                  'Ứng dụng nhắc uống thuốc gọn gàng, dữ liệu lưu cục bộ trên thiết bị.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showEditNameDialog() async {
    final TextEditingController controller =
        TextEditingController(text: widget.settings.displayName);

    final String? newName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sửa tên hiển thị'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Tên hiển thị',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      controller.dispose();
      return;
    }

    controller.dispose();

    if (newName == null) {
      return;
    }

    final String name = newName.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tên hiển thị không được để trống.')),
      );
      return;
    }

    setState(() {
      _isUpdatingDisplayName = true;
    });

    await widget.onUpdateDisplayName(name);

    if (!mounted) {
      return;
    }

    setState(() {
      _isUpdatingDisplayName = false;
    });
  }

  Future<void> _onToggleNotifications(bool enabled) async {
    setState(() {
      _isUpdatingNotifications = true;
    });

    await widget.onToggleNotifications(enabled);

    if (!mounted) {
      return;
    }

    setState(() {
      _isUpdatingNotifications = false;
    });
  }
}
