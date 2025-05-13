import 'dart:io';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../app_logger.dart';

/// שירות להקלטת שמע
class AudioRecordingService {
  final _audioRecorder = Record();
  String? _activePath;
  bool _isRecording = false;

  /// בדיקה האם השירות מקליט כרגע
  bool get isRecording => _isRecording;

  /// הנתיב לקובץ ההקלטה האחרון
  String? get lastRecordingPath => _activePath;

  /// יצירת נתיב לקובץ הקלטה זמני
  Future<String> _createTempFilePath() async {
    final tempDir = await getTemporaryDirectory();
    return '${tempDir.path}/audio_recording_${DateTime.now().millisecondsSinceEpoch}.wav';
  }

  /// התחלת הקלטת שמע
  Future<bool> startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        _activePath = await _createTempFilePath();

        // הגדרת איכות ההקלטה לפורמט WAV שנתמך היטב
        await _audioRecorder.start(
          path: _activePath,
          encoder: AudioEncoder.wav,
          bitRate: 128000,
          samplingRate: 44100,
        );

        AppLogger.instance.d('Start recording to path: $_activePath');
        _isRecording = true;
        return true;
      } else {
        AppLogger.instance.e('Recording permission not granted');
        return false;
      }
    } catch (e) {
      AppLogger.instance.e('Error starting recording: $e');
      return false;
    }
  }

  /// סיום הקלטת שמע
  Future<String?> stopRecording() async {
    try {
      if (_isRecording) {
        await _audioRecorder.stop();
        _isRecording = false;
        return _activePath;
      }
      return null;
    } catch (e) {
      AppLogger.instance.e('Error stopping recording: $e');
      _isRecording = false;
      return null;
    }
  }

  /// בחירת קובץ שמע מהמכשיר
  Future<Uint8List?> pickAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        File file = File(result.files.first.path!);
        _activePath = result.files.first.path;
        return await file.readAsBytes();
      }
      return null;
    } catch (e) {
      AppLogger.instance.e('Error picking audio file: $e');
      return null;
    }
  }

  /// קריאת קובץ השמע האחרון כבינארי
  Future<Uint8List?> getLastRecordingBytes() async {
    try {
      if (_activePath != null) {
        final file = File(_activePath!);
        if (await file.exists()) {
          return await file.readAsBytes();
        }
      }
      return null;
    } catch (e) {
      AppLogger.instance.e('Error reading recording: $e');
      return null;
    }
  }

  /// שחרור משאבים
  void dispose() {
    _audioRecorder.dispose();
  }
}
