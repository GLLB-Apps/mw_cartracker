import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart' as path_provider;

class SettingsService {
  bool isDarkMode = false;
  String? customBasePath; // Om användaren vill ha annan plats än Documents
  
  // Singleton pattern
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  Future<String> get basePath async {
    if (customBasePath != null) {
      return customBasePath!;
    }
    final directory = await path_provider.getApplicationDocumentsDirectory();
    return '${directory.path}/MakeWayTracker';
  }

  Future<void> ensureDirectoryExists() async {
    final path = await basePath;
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    
    // Create gameplay_sessions subdirectory
    final sessionsDir = Directory('$path/gameplay_sessions');
    if (!await sessionsDir.exists()) {
      await sessionsDir.create(recursive: true);
    }
  }

  Future<File> get _settingsFile async {
    final path = await basePath;
    return File('$path/settings.json');
  }

  Future<void> loadSettings() async {
    try {
      await ensureDirectoryExists();
      final file = await _settingsFile;
      
      if (await file.exists()) {
        final contents = await file.readAsString();
        final dynamic jsonData = json.decode(contents);
        
        isDarkMode = jsonData['isDarkMode'] ?? false;
        customBasePath = jsonData['customBasePath'];
      }
    } catch (e) {
      throw Exception('Error loading settings: $e');
    }
  }

  Future<void> saveSettings() async {
    try {
      await ensureDirectoryExists();
      final file = await _settingsFile;
      final jsonData = {
        'isDarkMode': isDarkMode,
        'customBasePath': customBasePath,
      };
      await file.writeAsString(json.encode(jsonData));
    } catch (e) {
      throw Exception('Error saving settings: $e');
    }
  }

  Future<void> setCustomBasePath(String? path) async {
    customBasePath = path;
    await saveSettings();
  }
}