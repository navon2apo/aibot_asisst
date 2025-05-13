import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../models/api_settings.dart';

class SettingsDialog extends StatefulWidget {
  final APISettings initialSettings;
  final Function(APISettings) onSave;

  const SettingsDialog({
    super.key,
    required this.initialSettings,
    required this.onSave,
  });

  @override
  _SettingsDialogState createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late TextEditingController apiKeyController;
  late TextEditingController modelController;
  late bool useOCR;
  late bool enableBrowsing;
  late bool enableWhisper;
  late bool enableSpeechRecognition;
  late String speechLocale;
  late bool allowDrawing;
  List<LocaleName> _locales = [];
  final SpeechToText _speechToText = SpeechToText();
  bool _isSpeechAvailable = false;

  @override
  void initState() {
    super.initState();
    apiKeyController = TextEditingController(
      text: widget.initialSettings.openAIKey,
    );
    modelController = TextEditingController(text: widget.initialSettings.model);
    useOCR = widget.initialSettings.useOCR;
    enableBrowsing = widget.initialSettings.enableBrowsing;
    enableWhisper = widget.initialSettings.enableWhisper;
    enableSpeechRecognition = widget.initialSettings.enableSpeechRecognition;
    speechLocale = widget.initialSettings.speechLocale;
    allowDrawing = widget.initialSettings.allowDrawing;

    // Load available locales for speech recognition only if not on Windows
    if (!Platform.isWindows) {
      _loadLocales();
    } else {
      print('Speech recognition locale loading skipped on Windows');
    }
  }

  Future<void> _loadLocales() async {
    try {
      bool available = await _speechToText.initialize(
        onError: (error) => print('Error loading locales: $error'),
        onStatus: (status) => print('Status: $status'),
      );

      if (available) {
        final locales = await _speechToText.locales();
        setState(() {
          _locales = locales;
          _isSpeechAvailable = true;
        });
      }
    } catch (e) {
      print('Exception during locale loading: $e');
      setState(() {
        _isSpeechAvailable = false;
      });
    }
  }

  @override
  void dispose() {
    apiKeyController.dispose();
    modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'הגדרות API',
        textAlign: TextAlign.right,
        style: GoogleFonts.assistant(fontWeight: FontWeight.bold, fontSize: 20),
      ),
      content: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'כדי להשתמש באפליקציה, אתה צריך מפתח API של OpenAI.',
                style: GoogleFonts.assistant(),
              ),
              SizedBox(height: 20),
              _buildHintBox(),
              SizedBox(height: 20),
              TextField(
                controller: apiKeyController,
                decoration: InputDecoration(
                  labelText: 'מפתח OpenAI API',
                  labelStyle: GoogleFonts.assistant(),
                  border: OutlineInputBorder(),
                  helperText: 'הזן את המפתח האישי שלך מ-OpenAI',
                  helperStyle: GoogleFonts.assistant(fontSize: 12),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: modelController,
                decoration: InputDecoration(
                  labelText: 'מודל',
                  labelStyle: GoogleFonts.assistant(),
                  border: OutlineInputBorder(),
                  helperText: 'למשל: gpt-4o, gpt-4-vision-preview',
                  helperStyle: GoogleFonts.assistant(fontSize: 12),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'יכולות:',
                style: GoogleFonts.assistant(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              _buildFeatureSwitch(
                title: 'זיהוי תמונות (OCR)',
                value: useOCR,
                onChanged: (value) {
                  setState(() {
                    useOCR = value;
                  });
                },
                subtitle: 'ניתוח והבנה של תמונות וצילומי מסך',
              ),
              _buildFeatureSwitch(
                title: 'גלישה באינטרנט',
                value: enableBrowsing,
                onChanged: (value) {
                  setState(() {
                    enableBrowsing = value;
                  });
                },
                subtitle: 'אפשר לעוזר לחפש מידע באינטרנט',
              ),
              _buildFeatureSwitch(
                title: 'הקלטת קול (Whisper)',
                value: enableWhisper,
                onChanged: (value) {
                  setState(() {
                    enableWhisper = value;
                  });
                },
                subtitle: 'המר הקלטות קוליות לטקסט',
              ),

              // Speech recognition feature - show with warning on Windows
              _buildFeatureSwitch(
                title: 'זיהוי דיבור',
                value: Platform.isWindows ? false : enableSpeechRecognition,
                onChanged: (value) {
                  setState(() {
                    enableSpeechRecognition = value;
                  });
                },
                subtitle:
                    Platform.isWindows
                        ? 'אינו נתמך כרגע בווינדוס'
                        : 'אפשר הקלדה באמצעות דיבור',
                disabled: Platform.isWindows,
              ),

              if (Platform.isWindows) _buildWindowsSpeechNotice(),

              if (enableSpeechRecognition &&
                  _locales.isNotEmpty &&
                  !Platform.isWindows)
                _buildLocaleDropdown(),
              _buildFeatureSwitch(
                title: 'אפשר ציור אחרי צילום מסך',
                value: allowDrawing,
                onChanged: (value) {
                  setState(() {
                    allowDrawing = value;
                  });
                },
                subtitle: 'הצג כלי ציור לאחר צילום מסך',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('ביטול', style: GoogleFonts.assistant()),
        ),
        ElevatedButton(
          onPressed: () {
            final newSettings = APISettings(
              openAIKey: apiKeyController.text,
              model: modelController.text,
              useOCR: useOCR,
              enableBrowsing: enableBrowsing,
              enableWhisper: enableWhisper,
              enableSpeechRecognition:
                  Platform.isWindows ? false : enableSpeechRecognition,
              speechLocale: speechLocale,
              allowDrawing: allowDrawing,
            );
            widget.onSave(newSettings);
            Navigator.pop(context);
          },
          child: Text('שמור', style: GoogleFonts.assistant()),
        ),
      ],
    );
  }

  Widget _buildWindowsSpeechNotice() {
    return Container(
      margin: EdgeInsets.only(top: 12, bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange[700],
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'הערה בנוגע לזיהוי דיבור:',
                style: GoogleFonts.assistant(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'פונקציית זיהוי הדיבור אינה נתמכת כרגע בגרסת Windows. אנו עובדים על פתרון לכך בגרסאות הבאות.',
            style: GoogleFonts.assistant(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildLocaleDropdown() {
    return Container(
      margin: EdgeInsets.only(top: 12, bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'שפת זיהוי הדיבור:',
            style: GoogleFonts.assistant(fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: speechLocale,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items:
                _locales.map((locale) {
                  return DropdownMenuItem<String>(
                    value: locale.localeId,
                    child: Text('${locale.name} (${locale.localeId})'),
                  );
                }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  speechLocale = value;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHintBox() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              SizedBox(width: 8),
              Text(
                'איך להשיג מפתח API:',
                style: GoogleFonts.assistant(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '1. היכנסו ל-platform.openai.com\n'
            '2. הירשמו או התחברו לחשבון\n'
            '3. לחצו על API Keys ואז "Create new secret key"',
            style: GoogleFonts.assistant(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureSwitch({
    required String title,
    required bool value,
    required Function(bool) onChanged,
    required String subtitle,
    bool disabled = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: disabled ? Colors.grey[100] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: GoogleFonts.assistant(
            fontWeight: FontWeight.w500,
            color: disabled ? Colors.grey[500] : Colors.grey[800],
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.assistant(
            fontSize: 12,
            color: disabled ? Colors.grey[500] : Colors.grey[600],
          ),
        ),
        value: value,
        onChanged: disabled ? null : onChanged,
        activeColor: Colors.deepPurple,
      ),
    );
  }
}
