import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/foundation.dart';
import 'models/api_settings.dart';
import 'models/chat_message.dart';
import 'repositories/chat_repo.dart';
import 'services/gpt_service.dart';
import 'services/screenshot_service.dart';
import 'services/audio_recording_service.dart';
import 'services/speech_service.dart';
import 'services/whisper_service.dart';
import 'ui/screens/home_screen_new.dart';
import 'controllers/chat_controller.dart';
import 'services/screenshot_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // אתחול Flutter Acrylic
  await Window.initialize();

  // שימוש באפקט שקוף חלקית
  await Window.setEffect(
    effect: WindowEffect.aero,
    color: Colors.white.withOpacity(0.5),
  );

  // הגדרות חלון
  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = WindowOptions(
      size: Size(400, 500),
      minimumSize: Size(400, 500),
      center: true,
      backgroundColor: Colors.transparent, // שימוש ברקע שקוף
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden, // שימוש בTitle Bar מותאם אישית
      // הגדרות נוספות
      alwaysOnTop: true, // תמיד מעל חלונות אחרים
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      // נגדיר את מניעת הסגירה ישירות
      await windowManager.setPreventClose(true);
    });
  }

  // הגדרת Hive
  await Hive.initFlutter();

  // רישום האדפטרים
  Hive.registerAdapter(APISettingsAdapter());
  Hive.registerAdapter(ChatMessageAdapter());

  await Hive.openBox('chat_history');
  await Hive.openBox('settings');

  // אתחול שירותים וריפוזיטורי
  final chatRepo = ChatRepo(
    chatHistoryBox: Hive.box('chat_history'),
    settingsBox: Hive.box('settings'),
  );
  final apiSettings = chatRepo.loadApiSettings(); // טוען מה-settingsBox
  print('[DEBUG] main.dart: apiSettings loaded = \\n${apiSettings.toJson()}');
  final gptService = GPTService(apiSettings);
  final screenshotService = ScreenshotService();
  final audioRecordingService = AudioRecordingService();
  final speechService = SpeechService(apiSettings);
  final whisperService = WhisperService(apiSettings);

  final screenshotManager = ScreenshotManager();
  final chatController = ChatController(
    chatRepo: chatRepo,
    gptService: gptService,
    screenshotService: screenshotService,
    audioRecordingService: audioRecordingService,
    speechService: speechService,
    whisperService: whisperService,
    screenshotManager: screenshotManager,
  );

  runApp(MyApp(chatController: chatController));

  // הגדרות לחלון באמצעות bitsdojo_window
  doWhenWindowReady(() {
    final win = appWindow;
    win.minSize = Size(400, 500);
    win.size = Size(400, 500);
    win.alignment = Alignment.center;
    win.title = "עוזר השולחן החכם";
    win.show();
  });
}

class MyApp extends StatelessWidget {
  final ChatController chatController;
  const MyApp({Key? key, required this.chatController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'סייען השולחן החכם',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Assistant',
        scaffoldBackgroundColor: Colors.white,
      ),
      home: HomeScreenNew(chatController: chatController),
    );
  }
}
