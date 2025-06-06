import 'package:hive_flutter/hive_flutter.dart';
import '../models/chat_message.dart';
import '../models/api_settings.dart';
import '../app_logger.dart';

/// ריפוזיטורי לניהול שיחות והיסטוריית צ'אט
class ChatRepo {
  final Box chatHistoryBox;
  final Box settingsBox;

  ChatRepo({required this.chatHistoryBox, required this.settingsBox});

  /// קבלת רשימת כל מזהי השיחות
  List<String> getChatSessions() {
    final sessions = settingsBox.get('chat_sessions');
    if (sessions != null) {
      return List<String>.from(sessions);
    }
    return [];
  }

  /// שמירת רשימת מזהי השיחות
  void saveChatSessions(List<String> chatSessions, {String? currentSessionId}) {
    settingsBox.put('chat_sessions', chatSessions);
    if (currentSessionId != null) {
      settingsBox.put('last_session_id', currentSessionId);
    }
  }

  /// קבלת מזהה השיחה האחרונה
  String? getLastSessionId() {
    return settingsBox.get('last_session_id');
  }

  /// טעינת היסטוריית שיחה לפי מזהה
  List<ChatMessage> loadChatHistory(String sessionId) {
    final historyData = chatHistoryBox.get(sessionId);
    if (historyData != null) {
      return List<ChatMessage>.from(historyData);
    }
    return [];
  }

  /// שמירת הודעה לשיחה
  void saveChatMessage(String sessionId, ChatMessage message) {
    List<ChatMessage> sessionData = [];
    final existingData = chatHistoryBox.get(sessionId);
    if (existingData != null) {
      sessionData = List<ChatMessage>.from(existingData);
    }
    sessionData.add(message);
    chatHistoryBox.put(sessionId, sessionData);
    // ודא שהשיחה ברשימת השיחות
    final sessions = getChatSessions();
    if (!sessions.contains(sessionId)) {
      sessions.add(sessionId);
      saveChatSessions(sessions, currentSessionId: sessionId);
    }
  }

  /// מחיקת היסטוריית שיחה
  void clearChatHistory(String sessionId) {
    chatHistoryBox.delete(sessionId);
  }

  /// יצירת מזהה שיחה חדש
  String createNewSessionId() {
    return "session_ ${DateTime.now().millisecondsSinceEpoch}";
  }

  /// מחיקת שיחה מהרשימה
  void deleteSession(String sessionId) {
    final sessions = getChatSessions();
    sessions.remove(sessionId);
    saveChatSessions(sessions);
    chatHistoryBox.delete(sessionId);
  }

  Map<String, String> getSessionNames() {
    final names = settingsBox.get('session_names');
    if (names != null) {
      return Map<String, String>.from(names);
    }
    return {};
  }

  String getSessionName(String sessionId) {
    final names = getSessionNames();
    return names[sessionId] ?? '';
  }

  void setSessionName(String sessionId, String name) {
    final names = getSessionNames();
    names[sessionId] = name;
    settingsBox.put('session_names', names);
  }

  void deleteSessionName(String sessionId) {
    final names = getSessionNames();
    names.remove(sessionId);
    settingsBox.put('session_names', names);
  }

  /// טעינת הגדרות API (APISettings) מה-settingsBox
  APISettings loadApiSettings() {
    final raw = settingsBox.get('api_settings');
    AppLogger.instance.d(
      '[DEBUG] loadApiSettings: raw from Hive = '
      '${raw != null ? raw.toString() : 'null'}',
    );
    if (raw != null) {
      final loaded = APISettings.fromJson(Map<String, dynamic>.from(raw));
      AppLogger.instance.d(
        '[DEBUG] loadApiSettings: loaded = '
        '\n${loaded.toJson()}',
      );
      return loaded;
    }
    AppLogger.instance.d(
      '[DEBUG] loadApiSettings: returning default APISettings',
    );
    return APISettings(); // ברירת מחדל
  }

  /// שמירת הגדרות API (APISettings) ל-settingsBox
  void saveApiSettings(APISettings settings) {
    AppLogger.instance.d(
      '[DEBUG] saveApiSettings: saving = ${settings.toJson()}',
    );
    settingsBox.put('api_settings', settings.toJson());
  }
}
