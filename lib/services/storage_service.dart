import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../models/medicine.dart';
import '../models/medicine_schedule.dart';

class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  static const String _medicinesKey = 'medicines';
  static const String _schedulesKey = 'schedules';
  static const String _settingsKey = 'settings';

  Future<List<Medicine>> loadMedicines() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? rawData = prefs.getString(_medicinesKey);

      if (rawData == null || rawData.isEmpty) {
        return <Medicine>[];
      }

      final List<dynamic> decoded = jsonDecode(rawData) as List<dynamic>;
      return decoded
          .map((dynamic item) =>
              Medicine.fromJson(
                  Map<String, dynamic>.from(item as Map<dynamic, dynamic>)))
          .toList();
    } catch (_) {
      return <Medicine>[];
    }
  }

  Future<bool> saveMedicines(List<Medicine> medicines) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String rawData =
          jsonEncode(medicines.map((Medicine e) => e.toJson()).toList());
      return prefs.setString(_medicinesKey, rawData);
    } catch (_) {
      return false;
    }
  }

  Future<List<MedicineSchedule>> loadSchedules() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? rawData = prefs.getString(_schedulesKey);

      if (rawData == null || rawData.isEmpty) {
        return <MedicineSchedule>[];
      }

      final List<dynamic> decoded = jsonDecode(rawData) as List<dynamic>;
      return decoded
          .map((dynamic item) => MedicineSchedule.fromJson(
              Map<String, dynamic>.from(item as Map<dynamic, dynamic>)))
          .toList();
    } catch (_) {
      return <MedicineSchedule>[];
    }
  }

  Future<bool> saveSchedules(List<MedicineSchedule> schedules) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String rawData =
          jsonEncode(schedules.map((MedicineSchedule e) => e.toJson()).toList());
      return prefs.setString(_schedulesKey, rawData);
    } catch (_) {
      return false;
    }
  }

  Future<AppSettings> loadSettings() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? rawData = prefs.getString(_settingsKey);

      if (rawData == null || rawData.isEmpty) {
        return AppSettings.initial();
      }

      final Map<String, dynamic> decoded =
          Map<String, dynamic>.from(jsonDecode(rawData) as Map<dynamic, dynamic>);
      return AppSettings.fromJson(decoded);
    } catch (_) {
      return AppSettings.initial();
    }
  }

  Future<bool> saveSettings(AppSettings settings) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String rawData = jsonEncode(settings.toJson());
      return prefs.setString(_settingsKey, rawData);
    } catch (_) {
      return false;
    }
  }
}
