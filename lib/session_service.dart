import 'dart:io';
import 'dart:convert';
import 'models.dart';
import 'settings_service.dart';

class SessionService {
  final SettingsService _settingsService = SettingsService();
  
  // Singleton pattern
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  Future<String> get _sessionsPath async {
    final basePath = await _settingsService.basePath;
    return '$basePath/gameplay_sessions';
  }

  Future<File> _getSessionFile(String sessionId) async {
    final path = await _sessionsPath;
    return File('$path/session_$sessionId.json');
  }

  Future<void> saveSession(GameSession session) async {
    try {
      await _settingsService.ensureDirectoryExists();
      final file = await _getSessionFile(session.id ?? '');
      await file.writeAsString(json.encode(session.toJson()));
    } catch (e) {
      throw Exception('Error saving session: $e');
    }
  }

  Future<List<GameSession>> loadAllSessions() async {
    try {
      await _settingsService.ensureDirectoryExists();
      final path = await _sessionsPath;
      final dir = Directory(path);
      
      if (!await dir.exists()) {
        return [];
      }

      final files = dir.listSync().whereType<File>().where((file) => 
        file.path.endsWith('.json') && file.path.contains('session_')
      ).toList();

      final sessions = <GameSession>[];
      for (var file in files) {
        try {
          final contents = await file.readAsString();
          final session = GameSession.fromJson(json.decode(contents));
          sessions.add(session);
        } catch (e) {
          // Skip corrupted files
          continue;
        }
      }

      // Sort by date, newest first
      sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
      return sessions;
    } catch (e) {
      throw Exception('Error loading sessions: $e');
    }
  }

  Future<void> deleteSession(String sessionId) async {
    try {
      final file = await _getSessionFile(sessionId);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Error deleting session: $e');
    }
  }

  Future<void> deleteAllSessions() async {
    try {
      final path = await _sessionsPath;
      final dir = Directory(path);
      
      if (await dir.exists()) {
        await for (var entity in dir.list()) {
          if (entity is File && entity.path.endsWith('.json')) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      throw Exception('Error deleting all sessions: $e');
    }
  }
}