import 'dart:math';

import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../models/medicine.dart';
import '../models/medicine_intake_record.dart';
import '../models/medicine_schedule.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/schedule_utils.dart';
import 'account_settings_page.dart';
import 'dashboard_page.dart';
import 'medicine_management_page.dart';
import 'schedule_management_page.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final StorageService _storageService = StorageService.instance;
  final NotificationService _notificationService = NotificationService.instance;

  final Random _random = Random();

  int _currentIndex = 0;
  bool _isLoading = true;

  List<Medicine> _medicines = <Medicine>[];
  List<MedicineSchedule> _schedules = <MedicineSchedule>[];
  List<MedicineIntakeRecord> _intakeRecords = <MedicineIntakeRecord>[];
  AppSettings _settings = AppSettings.initial();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final List<Medicine> medicines = await _storageService.loadMedicines();
      final List<MedicineSchedule> rawSchedules =
          await _storageService.loadSchedules();
      final List<MedicineIntakeRecord> rawIntakeRecords =
          await _storageService.loadIntakeRecords();
      AppSettings settings = await _storageService.loadSettings();

      // Migrate old non-accented default display name to accented text.
      final String oldDisplayName = settings.displayName.trim().toLowerCase();
      if (oldDisplayName == 'nguoi dung') {
        settings = settings.copyWith(displayName: 'Người dùng');
        await _storageService.saveSettings(settings);
      }

      final List<MedicineSchedule> normalizedSchedules =
          _normalizeSchedules(rawSchedules, medicines);
      final List<MedicineIntakeRecord> normalizedIntakeRecords =
          _normalizeIntakeRecords(rawIntakeRecords, normalizedSchedules);

      if (!mounted) {
        return;
      }

      setState(() {
        _medicines = medicines;
        _schedules = _sortedSchedules(normalizedSchedules);
        _intakeRecords = normalizedIntakeRecords;
        _settings = settings;
      });

      await _storageService.saveSchedules(_schedules);
      await _storageService.saveIntakeRecords(_intakeRecords);
      await _notificationService.syncAllSchedules(
        schedules: _schedules,
        notificationsEnabled: _settings.notificationsEnabled,
      );
    } catch (_) {
      _showSnackBar('Không thể tải dữ liệu ban đầu.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<MedicineSchedule> _normalizeSchedules(
    List<MedicineSchedule> schedules,
    List<Medicine> medicines,
  ) {
    final Map<String, Medicine> medicineById = <String, Medicine>{
      for (final Medicine medicine in medicines) medicine.id: medicine,
    };

    final Set<int> usedNotificationIds = <int>{};

    return schedules
        .where((MedicineSchedule schedule) {
          return medicineById.containsKey(schedule.medicineId);
        })
        .map((MedicineSchedule schedule) {
      int notificationId = schedule.notificationId;
      if (notificationId <= 0 || usedNotificationIds.contains(notificationId)) {
        notificationId = _generateNotificationId(usedNotificationIds);
      }
      usedNotificationIds.add(notificationId);

      final Medicine? linkedMedicine = medicineById[schedule.medicineId];
      final String resolvedMedicineName =
          linkedMedicine?.name ?? schedule.medicineName;
      final bool hasValidSpecificDate = schedule.specificDate != null;
      final bool useDaily = !schedule.isDaily && !hasValidSpecificDate;
      final bool shouldClearDate = schedule.isDaily || useDaily;

      return schedule.copyWith(
        medicineName: resolvedMedicineName,
        notificationId: notificationId,
        scheduleType: useDaily ? MedicineSchedule.typeDaily : schedule.scheduleType,
        clearDate: shouldClearDate,
      );
    }).toList();
  }

  List<MedicineSchedule> _sortedSchedules(List<MedicineSchedule> schedules) {
    final List<MedicineSchedule> sorted = List<MedicineSchedule>.from(schedules);
    sorted.sort((MedicineSchedule a, MedicineSchedule b) {
      final DateTime aNext = _nextOccurrenceForSort(a);
      final DateTime bNext = _nextOccurrenceForSort(b);
      final int byNextTime = aNext.compareTo(bNext);
      if (byNextTime != 0) {
        return byNextTime;
      }
      return a.medicineName.toLowerCase().compareTo(b.medicineName.toLowerCase());
    });
    return sorted;
  }

  List<MedicineIntakeRecord> _normalizeIntakeRecords(
    List<MedicineIntakeRecord> records,
    List<MedicineSchedule> schedules,
  ) {
    final Set<String> validScheduleIds =
        schedules.map((MedicineSchedule schedule) => schedule.id).toSet();
    final Map<String, MedicineIntakeRecord> normalized =
        <String, MedicineIntakeRecord>{};

    for (final MedicineIntakeRecord record in records) {
      if (!validScheduleIds.contains(record.scheduleId) ||
          record.dayKey.trim().isEmpty ||
          record.takenAt.trim().isEmpty) {
        continue;
      }
      normalized['${record.scheduleId}_${record.dayKey}'] = record;
    }

    return normalized.values.toList()
      ..sort((MedicineIntakeRecord a, MedicineIntakeRecord b) {
        return b.dayKey.compareTo(a.dayKey);
      });
  }

  DateTime _nextOccurrenceForSort(MedicineSchedule schedule) {
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
      return DateTime(9999, 12, 31, 23, 59);
    }

    final DateTime dateTime = DateTime(
      specificDate.year,
      specificDate.month,
      specificDate.day,
      schedule.hour,
      schedule.minute,
    );
    if (!dateTime.isAfter(now)) {
      return DateTime(9999, 12, 31, 23, 59);
    }
    return dateTime;
  }

  String _generateStringId() {
    return '${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(99999)}';
  }

  int _generateNotificationId(Set<int> usedIds) {
    int id = DateTime.now().millisecondsSinceEpoch % 2147483647;
    while (id <= 0 || usedIds.contains(id)) {
      id = (id + _random.nextInt(1000) + 1) % 2147483647;
    }
    return id;
  }

  Future<void> _saveMedicine(
    Medicine draft, {
    Medicine? oldMedicine,
  }) async {
    try {
      if (oldMedicine == null) {
        final Medicine newMedicine = draft.copyWith(id: _generateStringId());
        final List<Medicine> updatedMedicines =
            List<Medicine>.from(_medicines)..add(newMedicine);

        final bool saved = await _storageService.saveMedicines(updatedMedicines);
        if (!saved) {
          _showSnackBar('Không thể lưu thuốc mới.');
          return;
        }

        if (!mounted) {
          return;
        }

        setState(() {
          _medicines = updatedMedicines;
        });

        _showSnackBar('Đã thêm thuốc.');
        return;
      }

      final int index = _medicines.indexWhere((Medicine e) => e.id == oldMedicine.id);
      if (index == -1) {
        _showSnackBar('Không tìm thấy thuốc cần cập nhật.');
        return;
      }

      final Medicine updatedMedicine = draft.copyWith(id: oldMedicine.id);
      final List<Medicine> updatedMedicines = List<Medicine>.from(_medicines)
        ..[index] = updatedMedicine;

      final List<MedicineSchedule> updatedSchedules =
          _schedules.map((MedicineSchedule schedule) {
        if (schedule.medicineId != updatedMedicine.id) {
          return schedule;
        }
        return schedule.copyWith(medicineName: updatedMedicine.name);
      }).toList();

      final bool medicineSaved =
          await _storageService.saveMedicines(updatedMedicines);
      final bool scheduleSaved =
          await _storageService.saveSchedules(updatedSchedules);

      if (!medicineSaved || !scheduleSaved) {
        _showSnackBar('Không thể cập nhật thuốc.');
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _medicines = updatedMedicines;
        _schedules = _sortedSchedules(updatedSchedules);
      });

      if (_settings.notificationsEnabled) {
        await _notificationService.syncAllSchedules(
          schedules: _schedules,
          notificationsEnabled: true,
        );
      }

      _showSnackBar('Đã cập nhật thuốc.');
    } catch (_) {
      _showSnackBar('Có lỗi khi lưu thuốc.');
    }
  }

  Future<bool> _deleteMedicine(Medicine medicine) async {
    try {
      final bool isUsedInSchedule =
          _schedules.any((MedicineSchedule e) => e.medicineId == medicine.id);

      if (isUsedInSchedule) {
        _showSnackBar('Không thể xóa thuốc đang được sử dụng trong lịch.');
        return false;
      }

      final List<Medicine> updatedMedicines =
          List<Medicine>.from(_medicines)..removeWhere((Medicine e) => e.id == medicine.id);

      final bool saved = await _storageService.saveMedicines(updatedMedicines);
      if (!saved) {
        _showSnackBar('Không thể xóa thuốc.');
        return false;
      }

      if (!mounted) {
        return false;
      }

      setState(() {
        _medicines = updatedMedicines;
      });

      _showSnackBar('Đã xóa thuốc.');
      return true;
    } catch (_) {
      _showSnackBar('Có lỗi khi xóa thuốc.');
      return false;
    }
  }

  Future<void> _saveSchedule(
    MedicineSchedule draft, {
    MedicineSchedule? oldSchedule,
  }) async {
    try {
      if (oldSchedule == null) {
        final Set<int> usedNotificationIds =
            _schedules.map((MedicineSchedule e) => e.notificationId).toSet();

        final MedicineSchedule newSchedule = draft.copyWith(
          id: _generateStringId(),
          notificationId: _generateNotificationId(usedNotificationIds),
        );

        final List<MedicineSchedule> updatedSchedules =
            _sortedSchedules(List<MedicineSchedule>.from(_schedules)..add(newSchedule));

        final bool saved = await _storageService.saveSchedules(updatedSchedules);
        if (!saved) {
          _showSnackBar('Không thể tạo lịch mới.');
          return;
        }

        if (!mounted) {
          return;
        }

        setState(() {
          _schedules = updatedSchedules;
        });

        if (_settings.notificationsEnabled) {
          await _notificationService.scheduleReminder(newSchedule);
        }

        _showSnackBar('Đã tạo lịch uống thuốc.');
        return;
      }

      final int index =
          _schedules.indexWhere((MedicineSchedule e) => e.id == oldSchedule.id);
      if (index == -1) {
        _showSnackBar('Không tìm thấy lịch cần sửa.');
        return;
      }

      final MedicineSchedule updatedSchedule = draft.copyWith(
        id: oldSchedule.id,
        notificationId: oldSchedule.notificationId,
      );

      final List<MedicineSchedule> updatedSchedules =
          List<MedicineSchedule>.from(_schedules)..[index] = updatedSchedule;
      final List<MedicineSchedule> sortedUpdatedSchedules =
          _sortedSchedules(updatedSchedules);

      final bool saved =
          await _storageService.saveSchedules(sortedUpdatedSchedules);
      if (!saved) {
        _showSnackBar('Không thể cập nhật lịch.');
        return;
      }

      await _notificationService
          .cancelScheduleNotification(oldSchedule.notificationId);
      if (_settings.notificationsEnabled) {
        await _notificationService.scheduleReminder(updatedSchedule);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _schedules = sortedUpdatedSchedules;
      });

      _showSnackBar('Đã cập nhật lịch uống thuốc.');
    } catch (_) {
      _showSnackBar('Có lỗi khi lưu lịch.');
    }
  }

  Future<void> _deleteSchedule(MedicineSchedule schedule) async {
    try {
      final List<MedicineSchedule> updatedSchedules =
          List<MedicineSchedule>.from(_schedules)
            ..removeWhere((MedicineSchedule e) => e.id == schedule.id);
      final List<MedicineIntakeRecord> updatedRecords =
          List<MedicineIntakeRecord>.from(_intakeRecords)
            ..removeWhere(
              (MedicineIntakeRecord record) => record.scheduleId == schedule.id,
            );

      final bool schedulesSaved =
          await _storageService.saveSchedules(updatedSchedules);
      final bool recordsSaved =
          await _storageService.saveIntakeRecords(updatedRecords);
      if (!schedulesSaved || !recordsSaved) {
        _showSnackBar('Không thể xóa lịch.');
        return;
      }

      await _notificationService
          .cancelScheduleNotification(schedule.notificationId);

      if (!mounted) {
        return;
      }

      setState(() {
        _schedules = _sortedSchedules(updatedSchedules);
        _intakeRecords = updatedRecords;
      });

      _showSnackBar('Đã xóa lịch uống thuốc.');
    } catch (_) {
      _showSnackBar('Có lỗi khi xóa lịch.');
    }
  }

  Future<void> _toggleScheduleTakenToday(
    MedicineSchedule schedule,
    bool taken,
  ) async {
    final DateTime now = DateTime.now();
    if (!isScheduleDueOnDate(schedule, now)) {
      _showSnackBar('Lịch này không áp dụng cho hôm nay.');
      return;
    }

    final String todayKey = MedicineIntakeRecord.buildDayKey(now);
    final List<MedicineIntakeRecord> updatedRecords =
        List<MedicineIntakeRecord>.from(_intakeRecords)
          ..removeWhere((MedicineIntakeRecord record) {
            return record.scheduleId == schedule.id && record.dayKey == todayKey;
          });

    if (taken) {
      updatedRecords.add(
        MedicineIntakeRecord(
          scheduleId: schedule.id,
          dayKey: todayKey,
          takenAt: now.toIso8601String(),
        ),
      );
    }

    final bool saved = await _storageService.saveIntakeRecords(updatedRecords);
    if (!saved) {
      _showSnackBar('Không thể cập nhật trạng thái uống thuốc.');
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _intakeRecords = _normalizeIntakeRecords(updatedRecords, _schedules);
    });

    _showSnackBar(
      taken ? 'Đã đánh dấu uống thuốc hôm nay.' : 'Đã bỏ đánh dấu uống thuốc.',
    );
  }

  Future<void> _updateDisplayName(String displayName) async {
    try {
      final AppSettings updatedSettings =
          _settings.copyWith(displayName: displayName);

      final bool saved = await _storageService.saveSettings(updatedSettings);
      if (!saved) {
        _showSnackBar('Không thể lưu tên hiển thị.');
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _settings = updatedSettings;
      });

      _showSnackBar('Đã cập nhật tên hiển thị.');
    } catch (_) {
      _showSnackBar('Có lỗi khi cập nhật tên hiển thị.');
    }
  }

  Future<void> _toggleNotifications(bool enabled) async {
    try {
      final AppSettings updatedSettings =
          _settings.copyWith(notificationsEnabled: enabled);
      final bool saved = await _storageService.saveSettings(updatedSettings);

      if (!saved) {
        _showSnackBar('Không thể cập nhật cấu hình thông báo.');
        return;
      }

      await _notificationService.syncAllSchedules(
        schedules: _schedules,
        notificationsEnabled: enabled,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _settings = updatedSettings;
      });

      _showSnackBar(
        enabled
            ? 'Đã bật thông báo và đồng bộ lại lịch nhắc.'
            : 'Đã tắt thông báo và hủy toàn bộ lịch nhắc.',
      );
    } catch (_) {
      _showSnackBar('Có lỗi khi cập nhật thông báo.');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      DashboardPage(
        settings: _settings,
        medicines: _medicines,
        schedules: _schedules,
        intakeRecords: _intakeRecords,
        onNavigateToTab: _navigateToTab,
        onToggleTakenToday: _toggleScheduleTakenToday,
      ),
      ScheduleManagementPage(
        medicines: _medicines,
        schedules: _schedules,
        intakeRecords: _intakeRecords,
        notificationsEnabled: _settings.notificationsEnabled,
        onSaveSchedule: _saveSchedule,
        onDeleteSchedule: _deleteSchedule,
        onToggleTakenToday: _toggleScheduleTakenToday,
      ),
      MedicineManagementPage(
        medicines: _medicines,
        schedules: _schedules,
        onSaveMedicine: _saveMedicine,
        onDeleteMedicine: _deleteMedicine,
      ),
      AccountSettingsPage(
        settings: _settings,
        onUpdateDisplayName: _updateDisplayName,
        onToggleNotifications: _toggleNotifications,
      ),
    ];

    const List<String> pageTitles = <String>[
      'Tổng quan',
      'Lịch nhắc',
      'Tủ thuốc',
      'Tài khoản',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitles[_currentIndex]),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color(0xFFEFF5FF),
                Color(0xFFFDFEFF),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Color(0xFFF2F7FF),
                    AppTheme.pageBackground,
                    Color(0xFFFDFEFF),
                  ],
                ),
              ),
              child: IndexedStack(
                index: _currentIndex,
                children: pages,
              ),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          _navigateToTab(index);
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Tổng quan',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule_outlined),
            selectedIcon: Icon(Icons.schedule),
            label: 'Lịch',
          ),
          NavigationDestination(
            icon: Icon(Icons.medication_outlined),
            selectedIcon: Icon(Icons.medication),
            label: 'Tủ thuốc',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}
