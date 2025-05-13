import 'dart:async';
import 'dart:io';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import '../models/api_settings.dart';

class SpeechService {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  final StreamController<String> _textStreamController =
      StreamController<String>.broadcast();
  APISettings _settings;

  // Constructor with settings
  SpeechService(this._settings);

  // Public stream for accessing speech results
  Stream<String> get textStream => _textStreamController.stream;

  // Method to initialize speech recognition
  Future<bool> initialize() async {
    // Check if running on Windows - currently not supported properly
    if (Platform.isWindows) {
      print('Speech recognition temporarily disabled on Windows platform');
      _textStreamController.add("זיהוי דיבור אינו נתמך כרגע בגרסת Windows");
      return false;
    }

    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (error) => print('Speech recognition error: $error'),
        onStatus: (status) => print('Speech recognition status: $status'),
      );
      return _speechEnabled;
    } catch (e) {
      print('Error initializing speech recognition: $e');
      _textStreamController.add("אירעה שגיאה באתחול זיהוי דיבור: $e");
      return false;
    }
  }

  // Update settings
  void updateSettings(APISettings settings) {
    _settings = settings;
  }

  // Get available locales
  Future<List<LocaleName>> getLocales() async {
    if (Platform.isWindows) {
      return []; // Return empty list on Windows for now
    }

    try {
      return await _speechToText.locales();
    } catch (e) {
      print('Error getting locales: $e');
      return [];
    }
  }

  // Start listening with support for Hebrew
  Future<void> startListening({Function(String)? onResult}) async {
    if (Platform.isWindows) {
      _textStreamController.add("זיהוי דיבור אינו נתמך כרגע בגרסת Windows");
      return;
    }

    if (!_settings.enableSpeechRecognition) {
      _textStreamController.add("Speech recognition is disabled in settings");
      return;
    }

    if (!_speechEnabled) {
      bool initialized = await initialize();
      if (!initialized) {
        _textStreamController.add("Speech recognition not available");
        return;
      }
    }

    try {
      await _speechToText.listen(
        onResult: (SpeechRecognitionResult result) {
          _lastWords = result.recognizedWords;
          _textStreamController.add(_lastWords);
          if (onResult != null) {
            onResult(_lastWords);
          }
        },
        localeId: _settings.speechLocale,
        listenMode: ListenMode.confirmation,
        cancelOnError: true,
        partialResults: true,
      );
    } catch (e) {
      print('Error starting speech recognition: $e');
      _textStreamController.add("אירעה שגיאה בהפעלת זיהוי דיבור: $e");
    }
  }

  // Stop listening
  Future<void> stopListening() async {
    if (Platform.isWindows) {
      return;
    }

    try {
      await _speechToText.stop();
    } catch (e) {
      print('Error stopping speech recognition: $e');
    }
  }

  // Check if speech recognition is available
  bool get isAvailable => _speechEnabled && !Platform.isWindows;

  // Check if speech recognition is currently active
  bool get isListening => _speechToText.isListening && !Platform.isWindows;

  // Get the last recognized words
  String get lastWords => _lastWords;

  // Dispose resources
  void dispose() {
    try {
      if (!Platform.isWindows) {
        _speechToText.cancel();
      }
      _textStreamController.close();
    } catch (e) {
      print('Error disposing speech service: $e');
    }
  }
}
