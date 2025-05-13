import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/api_settings.dart';
import '../models/chat_message.dart';
import '../app_logger.dart';

class GPTService {
  final APISettings settings;
  bool _isInitialized = false;

  GPTService(this.settings) {
    _isInitialized =
        settings.openAIKey != null && settings.openAIKey!.isNotEmpty;
  }

  // Check if API key is valid
  Future<bool> validateAPIKey() async {
    if (settings.openAIKey == null || settings.openAIKey!.isEmpty) {
      return false;
    }

    try {
      final response = await http.get(
        Uri.parse('https://api.openai.com/v1/models'),
        headers: {'Authorization': 'Bearer ${settings.openAIKey}'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error validating API key: $e');
      AppLogger.instance.e('Error validating API key: $e');
      return false;
    }
  }

  // Send a request to GPT-4o with text and optional image
  Future<String> sendRequest({
    required String text,
    Uint8List? imageData,
    List<ChatMessage>? chatHistory,
  }) async {
    AppLogger.instance.d(
      '[DEBUG] GPTService.sendRequest: using openAIKey = '
      '${settings.openAIKey}',
    );
    if (settings.openAIKey == null || settings.openAIKey!.isEmpty) {
      return "No API key provided. Please enter an API key in settings.";
    }

    if (!_isInitialized) {
      return "Service not initialized. Please check your API settings.";
    }

    try {
      // Build message content
      List<Map<String, dynamic>> messageContent = [];

      // Add text content
      messageContent.add({'type': 'text', 'text': text});

      // Add image content if provided
      if (imageData != null) {
        final base64Image = base64Encode(imageData);
        messageContent.add({
          'type': 'image_url',
          'image_url': {'url': 'data:image/png;base64,$base64Image'},
        });
      }

      // Build messages array
      List<Map<String, dynamic>> messages = [
        {
          'role': 'system',
          'content':
              'אתה עוזר מועיל שעונה בעברית. אתה מסייע בניתוח טקסט והבנת תמונות. וודא שהתשובות שלך בעברית תקנית.',
        },
      ];

      // Add chat history if provided
      if (chatHistory != null && chatHistory.isNotEmpty) {
        for (var message in chatHistory) {
          messages.add({
            'role': message.isUser ? 'user' : 'assistant',
            'content': message.text,
          });
        }
      }

      // Add current message
      messages.add({'role': 'user', 'content': messageContent});

      // Make API request
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer ${settings.openAIKey}',
        },
        body: jsonEncode({
          'model': settings.model ?? 'gpt-4o',
          'messages': messages,
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        // Properly decode the response using UTF-8
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'];
        print('Response received successfully');
        AppLogger.instance.i('Response received successfully');
        return content;
      } else {
        print(
          'Error ${response.statusCode}: ${utf8.decode(response.bodyBytes)}',
        );
        AppLogger.instance.e(
          'Error ${response.statusCode}: ${utf8.decode(response.bodyBytes)}',
        );
        if (response.statusCode == 401) {
          return "שגיאת אימות: מפתח ה־API אינו תקף.";
        } else if (response.statusCode == 429) {
          return "חריגה ממגבלת קצב: אנא נסה שוב מאוחר יותר.";
        } else {
          return "שגיאה: ${response.statusCode} - ${_parseErrorMessage(utf8.decode(response.bodyBytes))}";
        }
      }
    } catch (e) {
      print('Error sending request: $e');
      AppLogger.instance.e('Error sending request: $e');
      return "שגיאה בשליחת הבקשה: $e";
    }
  }

  // Helper method to parse error messages from API response
  String _parseErrorMessage(String responseBody) {
    try {
      final data = jsonDecode(responseBody);
      if (data.containsKey('error') && data['error'].containsKey('message')) {
        return data['error']['message'];
      }
      return responseBody;
    } catch (e) {
      return responseBody;
    }
  }

  // Update settings
  void updateSettings(APISettings newSettings) {
    settings.openAIKey = newSettings.openAIKey;
    settings.model = newSettings.model;
    // הוסף כאן כל שדה נוסף ב-APISettings שצריך לעדכן
    _isInitialized =
        newSettings.openAIKey != null && newSettings.openAIKey!.isNotEmpty;
  }
}
