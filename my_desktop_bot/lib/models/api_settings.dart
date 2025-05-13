import 'package:hive/hive.dart';

part 'api_settings.g.dart';

@HiveType(typeId: 0)
class APISettings {
  @HiveField(0)
  String? openAIKey;

  @HiveField(1)
  String? model = 'gpt-4o';

  @HiveField(2)
  bool useOCR = true;

  @HiveField(3)
  bool enableBrowsing = true;

  @HiveField(4)
  bool enableWhisper = false;

  @HiveField(5)
  bool enableSpeechRecognition = true;

  @HiveField(6)
  String speechLocale = 'he_IL';

  @HiveField(7)
  bool allowDrawing = false;

  APISettings({
    this.openAIKey,
    this.model = 'gpt-4o',
    this.useOCR = true,
    this.enableBrowsing = true,
    this.enableWhisper = false,
    this.enableSpeechRecognition = true,
    this.speechLocale = 'he_IL',
    this.allowDrawing = false,
  });

  APISettings.fromJson(Map<String, dynamic> json)
    : openAIKey = json['openAIKey'],
      model = json['model'] ?? 'gpt-4o',
      useOCR = json['useOCR'] ?? true,
      enableBrowsing = json['enableBrowsing'] ?? true,
      enableWhisper = json['enableWhisper'] ?? false,
      enableSpeechRecognition = json['enableSpeechRecognition'] ?? true,
      speechLocale = json['speechLocale'] ?? 'he_IL',
      allowDrawing = json['allowDrawing'] ?? false;

  Map<String, dynamic> toJson() => {
    'openAIKey': openAIKey,
    'model': model,
    'useOCR': useOCR,
    'enableBrowsing': enableBrowsing,
    'enableWhisper': enableWhisper,
    'enableSpeechRecognition': enableSpeechRecognition,
    'speechLocale': speechLocale,
    'allowDrawing': allowDrawing,
  };
}
