import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/api_settings.dart';
import '../app_logger.dart';

/// שירות להמרת קול לטקסט באמצעות Whisper API של OpenAI
class WhisperService {
  final APISettings settings;
  bool _isInitialized = false;

  WhisperService(this.settings) {
    _isInitialized =
        settings.openAIKey != null &&
        settings.openAIKey!.isNotEmpty &&
        settings.enableWhisper;
  }

  /// בדיקה האם השירות מאותחל ומוכן לשימוש
  bool get isInitialized => _isInitialized;

  /// עדכון הגדרות השירות
  void updateSettings(APISettings newSettings) {
    _isInitialized =
        newSettings.openAIKey != null &&
        newSettings.openAIKey!.isNotEmpty &&
        newSettings.enableWhisper;
  }

  /// המרת נתוני שמע לטקסט באמצעות Whisper API
  /// [audioData] - נתוני השמע בפורמט בינארי
  /// [language] - קוד השפה (לדוגמה: "he" לעברית)
  /// [prompt] - הנחיה אופציונלית לשיפור הזיהוי
  Future<String> transcribeAudio({
    required Uint8List audioData,
    String language = 'he',
    String? prompt,
  }) async {
    if (!_isInitialized) {
      return "שירות Whisper לא מאותחל. אנא הפעל את האפשרות בהגדרות ווודא שמפתח API תקף.";
    }

    try {
      // שמירת נתוני השמע לקובץ זמני
      final tempFile = await _saveTempAudioFile(audioData);

      // יצירת בקשת multipart
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.openai.com/v1/audio/transcriptions'),
      );

      // הוספת headers
      request.headers.addAll({'Authorization': 'Bearer ${settings.openAIKey}'});

      // הוספת פרמטרים
      request.fields['model'] = 'whisper-1';
      request.fields['language'] = language;
      if (prompt != null && prompt.isNotEmpty) {
        request.fields['prompt'] = prompt;
      }

      // הוספת קובץ השמע
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          tempFile.path,
          filename: 'audio.wav',
        ),
      );

      // שליחת הבקשה
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // ניקוי קובץ זמני
      await tempFile.delete();

      // עיבוד התשובה
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['text'] ?? "לא זוהה טקסט בהקלטה";
      } else {
        final errorBody = utf8.decode(response.bodyBytes);
        AppLogger.instance.e('Error ${response.statusCode}: $errorBody');

        // טיפול טוב יותר בשגיאות נפוצות
        if (response.statusCode == 401) {
          return "שגיאת אימות: מפתח ה-API אינו תקף";
        } else if (response.statusCode == 400) {
          try {
            final errorJson = jsonDecode(errorBody);
            final errorMessage =
                errorJson['error']?['message'] ?? "שגיאה בפורמט הקובץ";
            return "שגיאה 400: $errorMessage";
          } catch (e) {
            return "שגיאה בפורמט הקובץ. וודא שאתה מקליט בפורמט נתמך.";
          }
        } else {
          return "שגיאה בשירות Whisper: ${response.statusCode}";
        }
      }
    } catch (e) {
      print("Error transcribing audio: $e");
      AppLogger.instance.e('Error transcribing audio: $e');
      return "שגיאה בהמרת הקול לטקסט: $e";
    }
  }

  /// שמירת נתוני השמע לקובץ זמני
  Future<File> _saveTempAudioFile(Uint8List audioData) async {
    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/temp_audio_${DateTime.now().millisecondsSinceEpoch}.wav',
    );
    await file.writeAsBytes(audioData);
    return file;
  }

  /// הקלטת קול מהמיקרופון והמרתו לטקסט
  /// הערה: יש להשתמש בחבילה נוספת להקלטת קול
  Future<String> recordAndTranscribe({
    int recordingDurationInSeconds = 10,
    String language = 'he',
    String? prompt,
  }) async {
    // כאן יש להוסיף קוד להקלטת קול מהמיקרופון
    // לדוגמה, שימוש בחבילת record או flutter_sound

    // שימוש בפונקציונליות ההקלטה של מערכת ההפעלה
    return "פונקציונליות הקלטה מהמיקרופון עדיין לא מיושמת";
  }
}
