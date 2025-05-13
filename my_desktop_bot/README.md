# סייען השולחן החכם - תיעוד פרויקט
עדכון חדש על המבנה והעבודה 

## Project Architecture:

### Core Structure:
- A Flutter desktop application primarily targeting Windows
- MVC-like architecture with a clear separation between UI, services, and models
- Multi-platform support (Windows, macOS, Linux, iOS, Android, web)

### Main Components:

1. **Services** (`lib/services/`):
   - `screenshot_manager.dart`: Manages screenshot functionality
   - `screenshot_service.dart`: Core screenshot implementation
   - `screen_region_selector_service.dart`: Handles selecting screen regions
   - `speech_service.dart` & `whisper_service.dart`: Speech recognition/processing
   - `audio_recording_service.dart`: Audio capture
   - `gpt_service.dart`: Integration with GPT APIs
   - `file_picker_service.dart`: File selection utility

2. **Models** (`lib/models/`):
   - `chat_message.dart` & `chat_message.g.dart`: Chat data structure with Hive adapters
   - `api_settings.dart` & `api_settings.g.dart`: API configuration storage

3. **UI** (`lib/ui/`):
   - **Screens** (`lib/ui/screens/`):
     - `home_screen.dart`: Main application screen (very large file - 1700+ lines)
   
   - **Widgets** (`lib/ui/widgets/`):
     - `window_title_bar.dart`: Custom window management
     - `screenshot_mode_dialog.dart`: Dialog for screenshot mode selection
     - `floating_menu.dart`: Floating menu interface
     - `settings_dialog.dart`: Configuration options
     - `chat_bubble.dart`: Chat message display
     - `window_size_display.dart`: Window dimension display

4. **Assets**:
   - `tessdata/` directory: Likely for OCR functionality
   - `tessdata_config.json`: Configuration for OCR

### Dependencies:
- **Window Management**: window_manager, flutter_acrylic, bitsdojo_window
- **Storage**: Hive, shared_preferences
- **Media Handling**: screenshot, record, image
- **API & Networking**: http
- **UI**: Google fonts
- **File System**: path_provider, file_picker
- **Permissions**: permission_handler
- **Native Integration**: ffi, win32

### Main Application Flow:
1. `main.dart` initializes window settings, Hive database, and UI configurations
2. HomeScreen is the primary interface with a large codebase
3. Services handle specific functionality (screenshots, speech, GPT integration)
4. Models manage data persistence using Hive

### Key Observations:
1. The home_screen.dart file is extremely large (1700+ lines), suggesting it may benefit from refactoring
2. The application appears to focus on desktop functionality with specialized window management
3. The architecture shows good separation between UI and services, but potentially needs more screens/views
4. Recent work has focused on screenshot functionality based on file organization

אפליקציית סייען שולחן חכם מבוססת על Flutter לסביבת Windows, המספקת ממשק בועה צפה עם יכולות עוזר חכם.

# סיכום השינויים שביצענו

## 1. ארגון מחדש של הקוד ושיפור הארכיטקטורה
- **הוצאת קוד משירותים מעמוד הבית**:
  - הפרדנו את ה-`ScreenshotModeDialog` מ-`home_screen.dart` לקובץ נפרד `screenshot_mode_dialog.dart`
  - הסרנו כפילויות קוד והפרדנו את הלוגיקה מהממשק

- **יצירת שירות ScreenshotManager חדש**:
  - שירות מרכזי שמנהל את כל פעולות צילום המסך ובחירת האזור
  - מתווך בין ה-UI לבין שירותי הצילום והבחירה
  - מפשט את הקוד בעמוד הבית והופך אותו לנקי יותר

## 2. פתרון בעיית בחירת אזור לצילום מסך
- **הוספת שירות screen_region_selector_service.dart**:
  - שירות ייעודי שמאפשר בחירת אזור על המסך באמצעות ממשק גרפי
  - מציג דיאלוג עם צילום המסך המלא ומאפשר גרירה לבחירת אזור

- **תיקון חישוב הקואורדינטות**:
  - שיפור מנגנון החישוב של קואורדינטות האזור הנבחר
  - התחשבות ביחס התצוגה של התמונה (aspect ratio)
  - תיקון בעיית החיתוך הלא מדויק של האזור שנבחר

- **תיקון בעיית "היעלמות הבחירה"**:
  - הוספת מצב `_selectionCompleted` שנשמר גם אחרי שחרור העכבר
  - כפתור האישור והאזור הנבחר נשארים מוצגים גם אחרי שחרור העכבר
  - שיפור ההנחיות למשתמש בהתאם למצב הבחירה

## 3. שיפור מנגנון צילום המסך וחיתוך
- **הוספת פונקציית cropScreenshot לשירות ScreenshotService**:
  - חיתוך מדויק של צילום המסך לפי קואורדינטות שנבחרו
  - בקרת שגיאות מתקדמת ומנגנון fallback

- **שיפור מנגנון הלוגים והדיאגנוסטיקה**:
  - לוגים מפורטים לאיתור בעיות
  - מעקב אחר תהליך החיתוך וחישוב הקואורדינטות

## 4. שיפורים לחוויית המשתמש
- **משוב למשתמש במהלך בחירת האזור**:
  - הנחיות שמשתנות בהתאם למצב הבחירה
  - הדגשה חזותית של האזור הנבחר

- **מדידות ומידע על האזור הנבחר**:
  - הצגת גודל האזור הנבחר (רוחב x גובה) בזמן הבחירה

הפתרונות שיישמנו מאפשרים כעת בחירת אזור מדויקת לצילום מסך, עם חווית משתמש משופרת ומבנה קוד נקי יותר. כל הקוד מאורגן בשירותים נפרדים עם אחריות מוגדרת היטב, מה שהופך את התחזוקה והרחבה עתידית לקלים יותר.

## תוכן העניינים

- [סקירה כללית](#סקירה-כללית)
- [ארכיטקטורה](#ארכיטקטורה)
- [תכונות עיקריות](#תכונות-עיקריות)
- [אינטגרציה עם GPT](#אינטגרציה-עם-gpt)
- [זיהוי קול ועיבוד](#זיהוי-קול-ועיבוד)
- [אחסון מקומי](#אחסון-מקומי)
- [התקנה והגדרה](#התקנה-והגדרה)
- [שלבי פיתוח](#שלבי-פיתוח)
- [עדכונים אחרונים](#עדכונים-אחרונים)
- [הרחבות עתידיות](#הרחבות-עתידיות)


## סקירה כללית

סייען השולחן החכם הוא אפליקציית שולחן עבודה מבוססת Flutter המתוכננת לפעול כעוזר חכם זמין באמצעות בועה צפה. המערכת משלבת את יכולות GPT-4o של OpenAI עם פונקציונליות מקומית כמו צילומי מסך וזיהוי קול כדי לספק חוויית משתמש רציפה.

האפליקציה פותחה בשפה העברית וכוללת תמיכה בתצוגה מימין לשמאל (RTL), ממשק משתמש מותאם לעברית, ויכולות זיהוי דיבור בעברית.

## ארכיטקטורה

האפליקציה בנויה על ארכיטקטורה מודולרית הכוללת את הרכיבים הבאים:

```
my_desktop_bot/
├── lib/
│   ├── models/          # מודלים לנתונים ומבני מידע
│   ├── services/        # שירותים עסקיים ואינטגרציות חיצוניות
│   └── ui/              
│       ├── screens/     # מסכים ראשיים
│       └── widgets/     # רכיבי ממשק קטנים וחוזרים
```

### מודלים עיקריים

1. **ChatMessage** - מייצג הודעת צ'אט עם תכונות כמו טקסט, שיוך (משתמש/מערכת), חותמת זמן, ונתוני תמונה אופציונליים.
2. **APISettings** - מחזיק את הגדרות ה-API כמו מפתח OpenAI, מודל בשימוש, והגדרות פונקציונליות.

### שירותים עיקריים

1. **GPTService** - מנהל תקשורת עם OpenAI API ומטפל בבקשות ותשובות.
2. **ScreenshotService** - מספק יכולות לכידת מסך.
3. **SpeechService** - מטפל בזיהוי דיבור והמרה לטקסט.
4. **WhisperService** - מספק המרת קול לטקסט באמצעות Whisper API של OpenAI.
5. **AudioRecordingService** - מנהל הקלטות קול באפליקציה.

### רכיבי ממשק

1. **HomeScreen** - המסך הראשי המכיל את הבועה הצפה וממשק הצ'אט.
2. **FloatingMenu** - בועה צפה גרירה עם תפריט פעולות.
3. **ChatBubble** - רכיב המציג הודעות צ'אט בודדות.
4. **SettingsDialog** - דיאלוג להגדרת מפתח API ואפשרויות נוספות.

## תכונות עיקריות

### בועה צפה עם תפריט

- **ממשק גרירה** - משתמשים יכולים לגרור את הבועה לכל מיקום במסך.
- **פעולות נגישות** - הבועה מרחיבה תפריט עם אפשרויות לצ'אט, צילום מסך, פקודות קוליות והגדרות.
- **אנימציות** - כוללת אנימציות חלקות למעברים ולמצבי פעולה שונים.

### ממשק צ'אט

- **היסטוריית הודעות** - מציג שיחות עם העוזר החכם בתצוגת צ'אט מוכרת.
- **תמיכה בתמונות** - מציג תמונות שנלכדו בצילומי מסך ישירות בשיחה.
- **אינדיקטור הקלדה** - מציג חיווי כאשר העוזר מעבד תשובה.
- **הקלטי קול** - תמיכה בקלט קולי ישירות בממשק הצ'אט.
- **חלון צ'אט גריר** - אפשרות להזיז את חלון הצ'אט לכל מקום במסך.
- **שינוי גודל** - יכולת לשנות את גודל חלון הצ'אט באמצעות גרירה.
- **ניהול שיחות** - תמיכה ביצירת שיחות חדשות ומעבר בין שיחות קיימות.

### שקיפות ועיצוב

- **שקיפות מלאה** - האפליקציה פועלת עם רקע שקוף ללא מסגרת מיותרת.
- **הודעות זמניות** - מציג הודעות סטטוס זמניות שנעלמות אוטומטית.
- **עיצוב מודרני** - ממשק נקי ואינטואיטיבי עם איקונים ברורים.

## אינטגרציה עם GPT

האפליקציה משתמשת ב-GPT-4o של OpenAI לספק תשובות חכמות ולנתח תמונות. האינטגרציה מתבססת על הרכיבים הבאים:

### GPTService

שירות זה מטפל בתקשורת עם OpenAI API ומפעיל את הפונקציונליות הבאה:

```dart
// שליחת בקשה לGPT-4o עם טקסט ותמונה אופציונלית
Future<String> sendRequest({
  required String text,
  Uint8List? imageData,
  List<ChatMessage>? chatHistory,
})
```

### תהליך התקשורת

1. **הכנת הבקשה** - הבקשה מוכנה עם טקסט המשתמש, היסטוריית הצ'אט, ותמונות אופציונליות.
2. **שליחה לAPI** - הנתונים נשלחים ישירות לOpenAI API באמצעות HTTP POST.
3. **עיבוד התשובה** - התשובה מעובדת ומוצגת בממשק הצ'אט.

### שימוש במפתח API

המשתמשים נדרשים להגדיר מפתח API של OpenAI דרך דיאלוג ההגדרות. המפתח נשמר מקומית ואינו נשלח לשום שרת חיצוני מלבד שרתי OpenAI.

### טיפול בקידוד תווים

כדי להבטיח שהתשובות בעברית מוצגות כראוי, נעשה שימוש בטכניקות הבאות:

1. **הגדרת charset=utf-8** - בכותרות הבקשה:
```dart
headers: {
  'Content-Type': 'application/json; charset=utf-8',
  'Authorization': 'Bearer ${settings.openAIKey}',
},
```

2. **פענוח תקין של תשובות** - שימוש ב-UTF-8 לפענוח התשובות:
```dart
final data = jsonDecode(utf8.decode(response.bodyBytes));
```

3. **הוראות ברורות למודל** - הגדרת prompt מערכת בעברית:
```dart
{
  'role': 'system',
  'content': 'אתה עוזר מועיל שעונה בעברית. אתה מסייע בניתוח טקסט והבנת תמונות. וודא שהתשובות שלך בעברית תקנית.',
},
```

## זיהוי קול ועיבוד

האפליקציה תומכת בשתי שיטות לזיהוי והמרת דיבור לטקסט:

### 1. זיהוי דיבור מקומי (Speech-to-Text)

שירות מקומי המשתמש בחבילת `speech_to_text`. **שים לב**: פונקציונליות זו אינה זמינה כרגע בפלטפורמת Windows בשל מגבלות הפלאגין.

```dart
// התחלת האזנה לדיבור מקומי
Future<void> startListening({Function(String)? onResult})
```

### 2. Whisper API (OpenAI)

שירות המשתמש ב-API של Whisper מבית OpenAI להמרת הקלטות קול לטקסט. זו האלטרנטיבה המומלצת בפלטפורמת Windows.

```dart
// המרת קובץ הקלטה לטקסט באמצעות Whisper
Future<String> transcribeAudio({
  required Uint8List audioData,
  String language = 'he',
  String? prompt,
})
```

### תהליך הקלטה ותמלול

1. **הקלטת קול** - המשתמש מקליט קול באמצעות לחיצה על כפתור המיקרופון.
2. **המרת הקלטה** - הקלטת הקול נשלחת ל-Whisper API להמרה לטקסט.
3. **תצוגת תוצאה** - התמלול מוצג בשדה ההודעה לעריכה אופציונלית.
4. **שליחה לצ'אט** - המשתמש יכול לערוך את התמלול ולשלוח אותו כהודעה.

### התמודדות עם מגבלות פלטפורמה

האפליקציה מזהה אוטומטית את הפלטפורמה ומתאימה את התנהגותה:

```dart
// זיהוי פלטפורמה והחרגות מתאימות
if (Platform.isWindows) {
  // השתמש בWhisper במקום זיהוי דיבור מקומי
} else {
  // השתמש בזיהוי דיבור מקומי אם זמין
}
```

בממשק המשתמש, האפליקציה מציגה הודעה מתאימה למשתמשים ב-Windows ומציעה חלופות.

## אחסון מקומי

האפליקציה משתמשת ב-Hive, מסד נתונים NoSQL קל משקל, לאחסון מקומי:

### אדפטרים של Hive

האפליקציה משתמשת באדפטרים של Hive כדי לאחסן את המודלים בצורה יעילה:

```dart
@HiveType(typeId: 0)
class APISettings {
  @HiveField(0)
  String? openAIKey;
  
  // שדות נוספים...
}

@HiveType(typeId: 1)
class ChatMessage {
  @HiveField(0)
  final String text;
  
  // שדות נוספים...
}
```

### ניהול שיחות

האפליקציה תומכת בשמירה וניהול של מספר שיחות נפרדות:

```dart
// שמירת הודעת צ'אט לשיחה הנוכחית
void _saveChatMessage(ChatMessage message) {
  try {
    final sessionKey = currentSessionId ?? "default_session";
    List<Map<String, dynamic>> sessionData = [];

    // טעינת נתוני השיחה הקיימים אם יש
    final existingData = chatHistoryBox.get(sessionKey);
    if (existingData != null) {
      sessionData = List<Map<String, dynamic>>.from(
        existingData.map((item) => Map<String, dynamic>.from(item)),
      );
    }

    // הוספת ההודעה החדשה
    sessionData.add(message.toMap());

    // שמירת כל השיחה
    chatHistoryBox.put(sessionKey, sessionData);
  } catch (e) {
    print("Error saving chat message: $e");
  }
}
```

### אחסון הגדרות

```dart
// שמירת הגדרות API
Future<void> _saveAPISettings() async {
  // שמירה ל-Hive
  await settingsBox.put('api_settings', apiSettings.toJson());
  
  // עדכון שירותים בהגדרות החדשות
  _gptService = GPTService(apiSettings);
  _speechService.updateSettings(apiSettings);
  _whisperService.updateSettings(apiSettings);
}
```

## התקנה והגדרה

### דרישות מערכת

- **מערכת הפעלה**: Windows 10 ומעלה
- **Flutter**: גרסה 3.7.0 ומעלה
- **זיכרון**: לפחות 4GB RAM
- **חיבור אינטרנט** נדרש לתקשורת עם OpenAI API

### הוראות התקנה

1. התקן Flutter SDK
2. שכפל את המאגר:
   ```
   git clone https://github.com/yourusername/my_desktop_bot.git
   ```
3. היכנס לתיקיית הפרויקט:
   ```
   cd my_desktop_bot
   ```
4. התקן את התלויות:
   ```
   flutter pub get
   ```
5. צור את קבצי האדפטר של Hive:
   ```
   flutter pub run build_runner build
   ```
6. הרץ את האפליקציה:
   ```
   flutter run -d windows
   ```

### הגדרה ראשונית

1. אחרי הפעלת האפליקציה, לחץ על אייקון ההגדרות בתפריט הבועה.
2. הזן את מפתח ה-API שלך מ-OpenAI.
3. בחר מודל מועדף (ברירת מחדל: gpt-4o).
4. הפעל או כבה יכולות לפי הצורך.
5. שמור את ההגדרות.

## שלבי פיתוח

להלן שלבי הפיתוח העיקריים של האפליקציה:

### שלב 1: הקמת הפרויקט ותשתית בסיסית

- יצירת מבנה פרויקט Flutter
- הגדרת חבילות נדרשות בקובץ pubspec.yaml
- יצירת מודלים בסיסיים וארכיטקטורת שירותים

### שלב 2: פיתוח ממשק משתמש

- יצירת בועה צפה גרירה עם אנימציות
- פיתוח ממשק צ'אט בסיסי
- הטמעת תמיכה בעברית וכיוון RTL
- עיצוב כללי וחווית משתמש

### שלב 3: אינטגרציית OpenAI

- פיתוח GPTService לתקשורת עם OpenAI API
- תמיכה בשליחת טקסט ותמונות
- הוספת דיאלוג הגדרות למפתח API
- ניהול תשובות והיסטוריית שיחה

### שלב 4: צילומי מסך ותמיכה בתמונות

- פיתוח ScreenshotService
- שילוב יכולת ללכוד חלקי מסך
- אינטגרציה של תמונות בשיחת הצ'אט
- הטמעת ניתוח תמונות עם GPT-4o

### שלב 5: זיהוי דיבור ועיבוד

- הוספת SpeechService לזיהוי דיבור
- הטמעת תמיכה בזיהוי דיבור בעברית
- הוספת משוב חזותי בזמן האזנה
- שילוב הקלט הקולי בממשק הצ'אט

### שלב 6: אחסון מקומי ועיצוב סופי

- הטמעת Hive לאחסון מקומי של נתונים
- שמירת היסטוריית שיחות והגדרות
- שיפור העיצוב וחווית המשתמש
- בדיקות וטיפול בשגיאות

### שלב 7: ניהול שיחות וממשק מתקדם

- הוספת תמיכה בניהול שיחות מרובות
- אפשרות מעבר בין שיחות שמורות
- יצירת שיחות חדשות ומחיקת שיחות קיימות
- שיפור ממשק ניהול השיחות

### שלב 8: שקיפות וגמישות ממשק

- הוספת שקיפות מלאה לחלון האפליקציה
- אפשרות הזזת חלון הצ'אט למיקום רצוי
- שינוי גודל דינמי לחלון הצ'אט
- שיפור חווית המשתמש הכוללת

## עדכונים אחרונים

### 1. תיקון אדפטרים של Hive

- הוספת אדפטרים מתאימים למודלים `APISettings` ו-`ChatMessage`
- שימוש ב-annotations לאפיון שדות ב-Hive
- שיפור מנגנון האחסון והטעינה של נתונים

```dart
@HiveType(typeId: 0)
class APISettings {
  @HiveField(0)
  String? openAIKey;
  // שדות נוספים...
}
```

### 2. שקיפות מלאה לחלון האפליקציה

- הוספת הגדרות לחלון שקוף באמצעות `flutter_acrylic`
- הסרת רקע האפליקציה לשקיפות מלאה
- שימוש ב-`windowManager` להגדרת חלון ללא מסגרת

```dart
await Window.initialize();
await Window.setEffect(
  effect: WindowEffect.transparent,
  color: Colors.transparent,
);
```

### 3. אפשרות הזזת חלון הצ'אט

- הוספת יכולת לגרור את חלון הצ'אט למיקום רצוי
- הוספת אייקון גרירה לכותרת חלון הצ'אט
- גמישות ממשק משופרת למשתמש

```dart
GestureDetector(
  onPanUpdate: (details) {
    setState(() {
      chatPosition = Offset(
        chatPosition.dx - details.delta.dx,
        chatPosition.dy + details.delta.dy,
      );
    });
  },
  child: Container(
    // תוכן הכותרת...
  ),
)
```

## הרחבות עתידיות

רשימת הרחבות פוטנציאליות לפיתוח עתידי:

1. **זיהוי דיבור משופר**
   - הוספת תמיכה ביותר שפות
   - שיפור דיוק זיהוי בעברית
   - זיהוי פקודות קוליות מותאמות אישית

2. **תמיכה במערכות הפעלה נוספות**
   - גרסה עבור macOS
   - גרסה עבור Linux
   - תמיכה בפלטפורמות ניידות

3. **העשרת API**
   - אינטגרציה עם API נוספים
   - יכולות חיפוש אינטרנט משופרות
   - חיבור למקורות מידע נוספים

4. **שיפורי ממשק**
   - אפשרויות התאמה אישית נוספות
   - תמות עיצוביות מותאמות אישית
   - אנימציות ואפקטים מתקדמים

5. **תמיכה בקלט קולי רציף**
   - זיהוי דיבור רציף ללא צורך בלחיצה על כפתור
   - זיהוי ומענה בזמן אמת
   - פקודות קוליות מוגדרות מראש

---

פותח באמצעות Flutter ו-Dart עם אינטגרציה עם OpenAI API.
