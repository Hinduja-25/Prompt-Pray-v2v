import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const String medicationsBoxName = 'medications_box';
  static const String appSettingsBoxName = 'settings_box';
  
  final _secureStorage = const FlutterSecureStorage();

  Future<void> init() async {
    await Hive.initFlutter();
    
    // Open standard boxes
    await Hive.openBox(medicationsBoxName);
    await Hive.openBox(appSettingsBoxName);
  }

  // --- Secure Storage Wrapper ---
  Future<void> writeSecure(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  Future<String?> readSecure(String key) async {
    return await _secureStorage.read(key: key);
  }

  Future<void> deleteSecure(String key) async {
    await _secureStorage.delete(key: key);
  }

  // --- Hive Box Accessors ---
  Box get medicationsBox => Hive.box(medicationsBoxName);
  Box get settingsBox => Hive.box(appSettingsBoxName);

  // Helper to save a custom preference
  void setPreference(String key, dynamic value) {
    settingsBox.put(key, value);
  }

  dynamic getPreference(String key, {dynamic defaultValue}) {
    return settingsBox.get(key, defaultValue: defaultValue);
  }
}
