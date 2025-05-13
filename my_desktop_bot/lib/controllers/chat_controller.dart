import 'package:flutter/material.dart';
import '../repositories/chat_repo.dart';
import '../services/gpt_service.dart';
import '../services/screenshot_service.dart';
import '../services/audio_recording_service.dart';
import '../services/speech_service.dart';
import '../services/whisper_service.dart';
import '../models/chat_message.dart';
import '../models/api_settings.dart';
import 'dart:typed_data';
import '../app_logger.dart';
import '../services/screenshot_manager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../ui/widgets/screenshot_editor.dart';
import 'dart:io' show Platform, File;
import 'package:file_picker/file_picker.dart';

/// ChatController - שכבת state/business logic לניהול שיחה
class ChatController extends ChangeNotifier {
  final ChatRepo chatRepo;
  final GPTService gptService;
  final ScreenshotService screenshotService;
  final AudioRecordingService audioRecordingService;
  final SpeechService speechService;
  final WhisperService whisperService;
  final ScreenshotManager screenshotManager;

  // מצב נוכחי
  List<ChatMessage> chatHistory = [];
  String? currentSessionId;
  List<String> chatSessions = [];
  bool isAssistantTyping = false;
  bool isRecording = false;
  bool isListening = false;
  bool isTranscribing = false;

  // UI State
  bool _showWindowSize = true;
  bool get showWindowSize => _showWindowSize;
  void toggleWindowSizeDisplay() {
    _showWindowSize = !_showWindowSize;
    notifyListeners();
  }

  bool _isChatVisible = false;
  bool get isChatVisible => _isChatVisible;
  void toggleChat() {
    _isChatVisible = !_isChatVisible;
    notifyListeners();
  }

  Offset _chatPosition = Offset(40, 45);
  Offset get chatPosition => _chatPosition;
  double _chatWidth = 320;
  double get chatWidth => _chatWidth;
  double _chatHeight = 400;
  double get chatHeight => _chatHeight;

  // Floating Action Button (FAB) position
  Offset _fabPosition = Offset(20, 80);
  Offset get fabPosition => _fabPosition;
  void updateFabPosition(Offset newPosition) {
    _fabPosition = newPosition;
    notifyListeners();
  }

  // Controllers
  final ScrollController scrollController = ScrollController();
  final TextEditingController messageController = TextEditingController();

  // Settings
  APISettings _apiSettings = APISettings();
  APISettings get apiSettings => _apiSettings;
  void updateSettings(APISettings newSettings) {
    _apiSettings = newSettings;
    notifyListeners();
  }

  // --- משתני UI נוספים לסנכרון מלא עם ה-UI ---
  bool isAlwaysOnTop = false;
  String? temporaryMessage;
  Animation<double> animation = AlwaysStoppedAnimation(1.0);
  late AnimationController animationController;
  final GlobalKey globalKey = GlobalKey();
  Uint8List? screenshotBytes;
  Offset position = Offset(20, 80);
  bool _isResizing = false;
  bool get isResizing => _isResizing;
  dynamic windowManager;

  // --- הוסף משתנה draftImage ---
  Uint8List? draftImage;

  // Constructor
  ChatController({
    required this.chatRepo,
    required this.gptService,
    required this.screenshotService,
    required this.audioRecordingService,
    required this.speechService,
    required this.whisperService,
    required this.screenshotManager,
  }) {
    _init();
  }

  void _init() {
    chatSessions = chatRepo.getChatSessions();
    currentSessionId = chatRepo.getLastSessionId() ?? "default_session";
    chatHistory = chatRepo.loadChatHistory(currentSessionId!);
  }

  /// שליחת הודעה (טקסט)
  Future<void> handleSubmit([String? text]) async {
    final msg = text ?? messageController.text;
    if (msg.trim().isEmpty && draftImage == null) return;
    // Add user message
    final userMessage = ChatMessage(
      text: msg,
      imageData: draftImage,
      isUser: true,
      timestamp: DateTime.now(),
    );
    chatHistory.add(userMessage);
    messageController.clear();
    draftImage = null;
    isAssistantTyping = true;
    notifyListeners();
    saveChatMessage(userMessage);
    scrollToBottom();

    // שלח ל-GPTService
    try {
      final response = await gptService.sendRequest(
        text: msg,
        chatHistory:
            chatHistory.length > 5
                ? chatHistory.sublist(chatHistory.length - 5)
                : chatHistory,
        imageData: userMessage.imageData,
      );
      final assistantMessage = ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      );
      chatHistory.add(assistantMessage);
      isAssistantTyping = false;
      notifyListeners();
      saveChatMessage(assistantMessage);
      scrollToBottom();
    } catch (e) {
      final errorMessage = ChatMessage(
        text: "שגיאה בשליחת הבקשה: $e",
        isUser: false,
        timestamp: DateTime.now(),
      );
      chatHistory.add(errorMessage);
      isAssistantTyping = false;
      notifyListeners();
      saveChatMessage(errorMessage);
      scrollToBottom();
    }
  }

  void scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// שמירת הודעה
  void saveChatMessage(ChatMessage message) {
    final sessionKey = currentSessionId ?? "default_session";
    chatRepo.saveChatMessage(sessionKey, message);
    if (!chatSessions.contains(sessionKey)) {
      chatSessions.add(sessionKey);
      chatRepo.saveChatSessions(chatSessions, currentSessionId: sessionKey);
    }
    notifyListeners();
  }

  Future<Uint8List> _maybeEditImage(
    BuildContext context,
    Uint8List image,
  ) async {
    if (!apiSettings.allowDrawing) return image;
    final edited = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(builder: (_) => ScreenshotEditor(initialImage: image)),
    );
    return edited ?? image;
  }

  // Screenshot
  Future<void> takeScreenshot(
    BuildContext context, {
    bool asUser = true,
  }) async {
    AppLogger.instance.d('[DEBUG] takeScreenshot: started');
    try {
      final result = await screenshotManager.takeScreenshot(
        context,
        appKey: globalKey,
      );
      if (result == null) {
        temporaryMessage = "המשתמש ביטל את צילום המסך";
        AppLogger.instance.i('[DEBUG] takeScreenshot: user cancelled');
        notifyListeners();
        return;
      }
      if (!result.success || result.bytes == null) {
        temporaryMessage = result.caption;
        AppLogger.instance.e(
          '[DEBUG] takeScreenshot: failed: \\${result.caption}',
        );
        notifyListeners();
        return;
      }
      // עריכה במידת הצורך
      final editedImage = await _maybeEditImage(context, result.bytes!);
      // דחיסה תמידית
      final compressed =
          (Platform.isWindows || Platform.isMacOS || Platform.isLinux)
              ? editedImage
              : await FlutterImageCompress.compressWithList(
                editedImage,
                quality: 70,
              );
      // שמור ב-draftImage
      draftImage = compressed;
      notifyListeners();
      temporaryMessage = null;
    } catch (e, stack) {
      AppLogger.instance.e('[DEBUG][ERROR] takeScreenshot: Exception: $e');
      AppLogger.instance.e(stack);
      temporaryMessage = "שגיאה בצילום המסך: $e";
      notifyListeners();
    }
  }

  // Image upload
  Future<void> uploadImage(BuildContext context) async {
    print('[DEBUG] uploadImage: Opening file picker...');
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    print('[DEBUG] uploadImage: Picker result = $result');
    if (result != null) {
      print('[DEBUG] uploadImage: result.files = \\${result.files}');
      print(
        '[DEBUG] uploadImage: result.files.single.bytes = \\${result.files.single.bytes}',
      );
    }
    Uint8List? imageBytes = result?.files.single.bytes;
    if (imageBytes == null &&
        result != null &&
        result.files.single.path != null) {
      print(
        '[DEBUG] uploadImage: bytes is null, reading from path: \\${result.files.single.path}',
      );
      imageBytes = await File(result.files.single.path!).readAsBytes();
      print(
        '[DEBUG] uploadImage: Loaded imageBytes from file, length = \\${imageBytes.length}',
      );
    }
    if (imageBytes != null) {
      print(
        '[DEBUG] uploadImage: Picked imageBytes.length = \\${imageBytes.length}',
      );
      print('[DEBUG] uploadImage: Calling _maybeEditImage...');
      final edited = await _maybeEditImage(context, imageBytes);
      print(
        '[DEBUG] uploadImage: _maybeEditImage returned \\${edited != null ? 'image of length \\${edited.length}' : 'null'}',
      );
      draftImage = edited;
      print('[DEBUG] uploadImage: draftImage set. Calling notifyListeners...');
      notifyListeners();
      print('[DEBUG] uploadImage: notifyListeners called.');
    } else {
      print('[DEBUG] uploadImage: No image selected or bytes are null.');
    }
  }

  // Voice
  void toggleVoice() {
    // Stub: implement voice logic
    // ...
    notifyListeners();
  }

  // Audio recording + Whisper transcription
  Future<void> toggleAudioRecording() async {
    try {
      AppLogger.instance.d(
        '[DEBUG] toggleAudioRecording: isRecording = $isRecording',
      );
      if (!isRecording) {
        AppLogger.instance.d('[DEBUG] toggleAudioRecording: Start recording');
        final started = await audioRecordingService.startRecording();
        AppLogger.instance.d(
          '[DEBUG] toggleAudioRecording: startRecording returned $started',
        );
        if (started) {
          isRecording = true;
          temporaryMessage = "מקליט... לחץ שוב כדי לעצור";
          notifyListeners();
        } else {
          temporaryMessage = "לא ניתן להתחיל הקלטה (אין הרשאה?)";
          notifyListeners();
        }
      } else {
        AppLogger.instance.d('[DEBUG] toggleAudioRecording: Stop recording');
        isRecording = false;
        isTranscribing = true;
        temporaryMessage = "ממיר את ההקלטה לטקסט...";
        notifyListeners();
        final path = await audioRecordingService.stopRecording();
        AppLogger.instance.d(
          '[DEBUG] toggleAudioRecording: stopRecording returned path = $path',
        );
        if (path == null) {
          temporaryMessage = "שגיאה: לא התקבל קובץ הקלטה";
          isTranscribing = false;
          notifyListeners();
          return;
        }
        AppLogger.instance.d(
          '[DEBUG] toggleAudioRecording: Reading audio bytes from $path',
        );
        final bytes = await audioRecordingService.getLastRecordingBytes();
        AppLogger.instance.d(
          '[DEBUG] toggleAudioRecording: getLastRecordingBytes returned: '
          '${bytes != null ? bytes.length : 'null'} bytes',
        );
        if (bytes == null) {
          temporaryMessage = "שגיאה בקריאת קובץ ההקלטה";
          isTranscribing = false;
          notifyListeners();
          return;
        }
        AppLogger.instance.d(
          '[DEBUG] toggleAudioRecording: Calling whisperService.transcribeAudio',
        );
        final transcript = await whisperService.transcribeAudio(
          audioData: bytes,
          language: apiSettings.speechLocale.startsWith('he') ? 'he' : 'en',
        );
        AppLogger.instance.d(
          '[DEBUG] toggleAudioRecording: whisperService.transcribeAudio returned: $transcript',
        );
        if (transcript != null && transcript.isNotEmpty) {
          messageController.text = transcript;
          temporaryMessage = null;
        } else {
          temporaryMessage = "לא התקבל תמלול";
        }
        isTranscribing = false;
        notifyListeners();
      }
    } catch (e, stack) {
      AppLogger.instance.e(
        '[DEBUG][ERROR] toggleAudioRecording: Exception: $e',
      );
      AppLogger.instance.e(stack);
      temporaryMessage = "שגיאה בתהליך ההקלטה/תמלול";
      isRecording = false;
      isTranscribing = false;
      notifyListeners();
    }
  }

  void createNewSession(String name) {
    final newSessionId = chatRepo.createNewSessionId();
    currentSessionId = newSessionId;
    chatHistory = [];
    if (!chatSessions.contains(newSessionId)) {
      chatSessions.add(newSessionId);
    }
    chatRepo.saveChatSessions(chatSessions, currentSessionId: newSessionId);
    chatRepo.chatHistoryBox.put(newSessionId, <ChatMessage>[]);
    setSessionName(newSessionId, name);
    notifyListeners();
  }

  void clearHistory() {
    if (currentSessionId != null) {
      chatRepo.clearChatHistory(currentSessionId!);
      chatHistory = [];
      notifyListeners();
    }
  }

  String getSessionName(String sessionId) {
    return chatRepo.getSessionName(sessionId);
  }

  void setSessionName(String sessionId, String name) {
    chatRepo.setSessionName(sessionId, name);
    notifyListeners();
  }

  void deleteSessionName(String sessionId) {
    chatRepo.deleteSessionName(sessionId);
    notifyListeners();
  }

  /// מעבר בין סשנים - טען היסטוריית צ'אט לסשן שנבחר
  void switchSession(String sessionId) {
    currentSessionId = sessionId;
    chatHistory = chatRepo.loadChatHistory(sessionId);
    notifyListeners();
  }

  @override
  void dispose() {
    scrollController.dispose();
    messageController.dispose();
    super.dispose();
  }

  // --- Setters ל-state משתנה ---
  set chatPosition(Offset value) {
    _chatPosition = value;
    notifyListeners();
  }

  set chatWidth(double value) {
    _chatWidth = value;
    notifyListeners();
  }

  set chatHeight(double value) {
    _chatHeight = value;
    notifyListeners();
  }

  set isChatVisible(bool value) {
    _isChatVisible = value;
    notifyListeners();
  }

  set isResizing(bool value) {
    _isResizing = value;
    notifyListeners();
  }
}
