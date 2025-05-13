# Refactor & Architecture Log: Desktop Flutter Bot

## Purpose
This document logs every step, decision, and insight during the process of refactoring the home screen and separating business logic from UI, as per the user's request.

---

## Step 1: Initial Analysis (Completed)

### 1.1. Home Screen Analysis
- **File:** `lib/ui/screens/home_screen.dart`
- **Findings:**
  - The file contains a mix of UI code and business logic (session management, chat history, API calls, screenshot logic, audio recording, etc.).
  - Many services and repositories are directly instantiated and used in the UI layer.
  - The UI is tightly coupled to the logic, making maintenance and testing difficult.

### 1.2. Business Logic & Data Layer Mapping
- **Services:**
  - `gpt_service.dart`: Handles GPT API requests.
  - `screenshot_service.dart`: Handles all screenshot logic.
  - `audio_recording_service.dart`: Handles audio recording.
  - `speech_service.dart`: Handles speech-to-text.
  - `whisper_service.dart`: Handles audio transcription.
  - `file_picker_service.dart`: Handles file/image picking.
- **Repositories:**
  - `chat_repo.dart`: Handles chat session and message persistence.
- **Controllers:**
  - `chat_controller.dart`: Provides a ChangeNotifier-based state/business logic layer for chat, session, and media actions.
- **Models:**
  - `chat_message.dart`, `api_settings.dart`: Define the data structures for chat messages and API settings.

### 1.3. UI Layer Mapping
- **Widgets:**
  - `floating_menu.dart`, `window_title_bar.dart`, `settings_dialog.dart`, `chat_bubble.dart`, `window_size_display.dart`, `screenshot_mode_dialog.dart`: Modular UI components used in the home screen.

---

## Step 2: Feature & Flow Summary (Completed)

### 2.1. Major Features in Home Screen
- **Chat Window**: Floating, draggable, resizable chat window with animated open/close.
- **Chat Sessions**: Multiple chat sessions, session management (create, load, delete, switch), persistent history per session.
- **Message Handling**: User and assistant messages, including text and images, with timestamp and sender indication.
- **Screenshot Integration**: Capture full screen, region, or window; attach screenshot to chat; handle screenshot errors.
- **Image Upload**: Upload image from file picker and attach to chat.
- **Voice Input**: Start/stop speech-to-text (if supported), insert recognized text into input.
- **Audio Recording & Transcription**: Record audio, transcribe to text using Whisper, insert transcription into input.
- **API Key & Settings Management**: Dialog for API key and settings, persistent storage, update services on change.
- **Always On Top**: Toggle window always-on-top state, with feedback.
- **Temporary Messages**: Show temporary status/info messages to user (e.g., recording, transcribing, errors).
- **Window Size Display**: Toggle display of window size.
- **Floating Action Menu**: Draggable, lockable floating menu for quick access to chat, screenshot, voice, settings, etc.
- **RTL Support**: All UI is right-to-left (Hebrew).

### 2.2. User Flows
- **Start New Chat**: User opens chat, creates new session, history is cleared, system message is shown.
- **Switch Chat Session**: User selects previous session, chat history is loaded.
- **Send Message**: User types message, submits, message is added to chat, sent to GPT, response is shown.
- **Send Image/Screenshot**: User uploads image or takes screenshot, image is attached to chat, can be referenced in next message.
- **Voice Input**: User starts voice input, speaks, recognized text appears in input, can be edited and sent.
- **Audio Recording**: User records audio, stops, transcription appears in input, can be edited and sent.
- **Settings Update**: User opens settings, updates API key or options, services are updated, confirmation message shown.
- **Always On Top**: User toggles always-on-top, window state is updated, feedback shown.
- **Resize/Move Chat**: User drags/resizes chat window, position and size are updated live.
- **Clear History**: User clears chat history, confirmation dialog shown, history is deleted.

---

## Step 3: UI Mapping & Preservation (Completed)

### 3.1. UI Components to Preserve
- All UI widgets in `lib/ui/widgets/` will be preserved and reused as-is:
  - `floating_menu.dart`
  - `window_title_bar.dart`
  - `settings_dialog.dart`
  - `chat_bubble.dart`
  - `window_size_display.dart`
  - `screenshot_mode_dialog.dart`
- The visual structure, layout, and user experience will remain unchanged.
- Only the business logic will be refactored out of the UI; all UI code and design will be kept.

### 3.2. Screens
- Only `home_screen.dart` will be rebuilt, using the above widgets and the same UI structure.
- No other screens found in `lib/ui/screens/`.

---

## Step 4: Real Chat Message Sending (Completed)

- Updated `ChatController.handleSubmit` to use the real `GPTService` for sending user messages and receiving assistant responses.
- When the user sends a message, it is now sent to the GPT API, and the assistant's real response is displayed in the chat.
- Error handling is included: if the API call fails, an error message is shown in the chat.
- The UI remains unchanged; only the business logic is now real and connected to the backend.
- This brings the chat experience in the new UI to parity with the old home screen for text messages.

---

## [2024-06-09] הטמעת Logger חכם (AppLogger)

### מה בוצע?
- הוספנו את חבילת `logger` ל־pubspec.yaml.
- נוצר קובץ עזר מרכזי `app_logger.dart` עם Logger סינגלטון (PrettyPrinter).
- כל קריאות ה־print בקוד הומרו לשימוש ב־AppLogger.instance (debug/info/error) בקבצים:
  - controllers/chat_controller.dart
  - services/audio_recording_service.dart
  - services/whisper_service.dart
  - services/gpt_service.dart
  - repositories/chat_repo.dart
- כל הודעות הלוג כעת מסודרות, עם רמות חשיבות, תאריך, מקור, וניתנות לשליטה מרכזית.

### יתרונות:
- שליטה קלה על רמות הלוג (debug/info/error).
- אפשרות להסתיר לוגים ב־release.
- פורמט מסודר ואחיד לכל ההודעות.
- בסיס להרחבה ללוגים לקובץ/שרת בעתיד.

### איך משתמשים?
- במקום print, יש לכתוב:
  - `AppLogger.instance.d('debug message');`
  - `AppLogger.instance.i('info message');`
  - `AppLogger.instance.e('error message');`

---

## [2024-06-09] שיפורי UX בצילום מסך וגלילה בצ'אט

### מה בוצע?
- צילום מסך מהתפריט הצף (FloatingMenu) פותח אוטומטית את הצ'אט, כך שהמשתמש רואה מיד את התמונה שנוספה.
- לאחר כל הוספת הודעה חדשה (כולל צילום מסך), הצ'אט גולל אוטומטית לסוף – המשתמש תמיד רואה את ההודעה/תמונה האחרונה.

### קבצים שהושפעו:
- `ui/screens/home_screen_new.dart` (פתיחת צ'אט אוטומטית, גלילה אוטומטית לסוף)
- `controllers/chat_controller.dart` (שיפורי scrollToBottom)

### ערך למשתמש:
- חוויית שימוש חלקה: אין צורך לגלול ידנית כדי לראות הודעות חדשות או תמונות שצולמו.
- כל צילום מסך מוצג מיד בצ'אט, ללא בלבול או צורך בפתיחה ידנית.

---

## [2024-06-10] שדרוג עורך צילום המסך (Screenshot Editor)

### מה בוצע?
- **פאן/זום מודרני:**
  - הוסר מצב "יד" (פאן) מהטולבר ומהקוד.
  - נוספו Scrollbars רגילים (אופקי ואנכי) שמופיעים רק כאשר יש זום שונה מ־100%.
  - הסליידרים ממוקמים מחוץ לקנבס, לא מכסים אותו, ומאפשרים פאן אינטואיטיבי.
- **כפתור "התאם למסך" (Fit to Canvas):**
  - נוסף כפתור ליד הסליידר של הזום.
  - בלחיצה, התמונה והציורים חוזרים למצב כניסה (רואים את כל התמונה, זום 1.0, סקרולרים מאופסים).
  - כאשר מזיזים את הסליידר לזום 1.0, הסקרולרים מתאפסים אוטומטית.
- **נעילת סקרול בזמן ציור/גרירה:**
  - עטפתי את FlutterPainter ב־GestureDetector.
  - בעת התחלת ציור/גרירה (onPanDown/onPanStart) — הסקרולרים ננעלים (NeverScrollableScrollPhysics).
  - בסיום (onPanEnd/onPanCancel) — הסקרולרים חוזרים לפעולה רגילה.
  - כך נמנעת תזוזה לא רצויה של הקנבס בזמן עריכה.
- **זום אחיד לכל הקנבס (תמונה + ציור):**
  - ה־Stack של התמונה והציור עטוף ב־Transform.scale (scale: _zoomScale).
  - ה־SizedBox של הקנבס הוא תמיד בגודל התמונה המקורית.
  - הזום מוחל על כל הקנבס יחד, כך שכל האלמנטים (ציור, טקסט, חיצים וכו') שומרים על מיקום יחסי גם בזום.
  - אין יותר "בריחה" של ציורים/אובייקטים מהתמונה בזמן זום.

### איך לבדוק?
1. **פאן/זום:**
   - תוכל לבצע זום פנימה/החוצה, והסליידרים יאפשרו להזיז את הקנבס.
   - אין יותר מצב יד, אין פאן עם העכבר — רק עם הסליידרים.
2. **ציור/גרירה:**
   - בזמן ציור או גרירת אובייקט, הקנבס לא יזוז.
   - תוכל לצייר, לגרור, ולגלול — בלי שהקנבס יזוז בטעות.
3. **התאם למסך:**
   - בלחיצה על כפתור "התאם למסך" או החזרת הזום ל־1.0, הכל חוזר למצב כניסה (רואים את כל התמונה, ממורכזת).
4. **זום אחיד:**
   - כל האלמנטים (תמונה + ציור) שומרים על מיקום יחסי גם בזום.

### קבצים שהושפעו:
- `lib/ui/widgets/screenshot_editor.dart`

### הערות:
- כל שינוי בוצע בשלבים, עם תיעוד, בדיקות, ושמירה על ארכיטקטורה מבודדת.
- המערכת כעת יציבה, מודרנית, ונוחה לשימוש — עם פאן/זום מקצועי, ציור מדויק, ו־UI נקי.

---

## [2024-05 — 2024-06] מערכת צילום מסך ועריכת ציור — פיצ'רים, ארכיטקטורה ותיעוד

### צילום מסך
- תמיכה במצבי צילום: מסך מלא, אזור נבחר, חלון בודד.
- אינטגרציה מלאה עם הצ'אט: כל צילום מצורף אוטומטית להודעה.
- טיפול בשגיאות צילום (הרשאות, קבצים, clipboard).
- שמירה אוטומטית של תמונה זמנית, דחיסת תמונה לפני שליחה.
- אפשרות להעלות תמונה חיצונית לקנבס.

### עורך ציור (Screenshot Editor)
- שכבות: כל ציור/טקסט/צורה נשמרים כאובייקטים נפרדים, עם אפשרות עריכה בזמן אמת.
- כלי ציור: מברשת, חץ, מלבן, עיגול, טקסט, מחק.
- העלאת תמונה נוספת לקנבס (image overlay).
- מחיקת אלמנט בודד (בחירה + Delete), מחיקת כל הציור.
- Undo/Redo מלא לכל פעולה.
- בחירת צבע, עובי, שקיפות, מילוי/קו, גודל טקסט.
- מחק (eraser) עם שליטה בגודל.
- פידבק ויזואלי לכל כלי נבחר, אפשרות לבטל בחירה.
- סרגל כלים מודרני, סרגל הגדרות דינמי (scroll hint).
- תמיכה מלאה בעברית ובאנגלית (כל הטקסטים, tooltips, הנחיות).
- הנחיות למשתמש (הסבר על זום/פאן, גלילה, מחיקה).
- זום/פאן: סליידר זום, פאן עם scrollbars, התאמה למסך (Fit to Canvas), שמירה על מיקום יחסי של כל האלמנטים.
- העלאת תמונה חיצונית, מיזוג שכבות, דחיסת תמונה לפני שליחה.
- טיפול בבאגים: תזוזת קנבס בזמן ציור, בריחת ציורים בזום, שגיאות layout, תיקוני פלאגינים (file_picker, flutter_painter).
- תרגום מלא לאנגלית של כל ה-UI.

### ארכיטקטורה והנדסה
- הפרדת לוגיקה מה-UI: כל הלוגיקה (ציור, שמירה, העלאה, הגדרות) מרוכזת ב-controllers/services.
- שמירת הגדרות משתמש (צבע, עובי, מצב מילוי) ב-Hive, שימוש חוזר בכל השירותים.
- תיעוד שינויים מסודר (log), עבודה בשלבים, checkpoint אחרי כל פיצ'ר.
- בדיקות UX: כל פיצ'ר נבדק ידנית, כולל פידבק מהמשתמש, תיקון לוגים, שיפורי נגישות.
- טיפול בבאגים: תיעוד, דיבאג, תיקון לוגיקה, עדכון פלאגינים ב-third_party.
- עבודה עם פלאגינים מועתקים (file_picker, flutter_painter) — תיקון קוד, עדכון pubspec, rebuild.

### איך לבדוק?
- צילום מסך: בדוק כל מצב צילום, ודא שהתמונה מצורפת לצ'אט.
- ציור: נסה כל כלי, מחק, Undo/Redo, שינוי צבע/עובי/שקיפות, העלאת תמונה, מחיקת אלמנט.
- זום/פאן: בצע זום, גרור סליידרים, לחץ "התאם למסך" — ודא שהכל נשאר במקום.
- בדוק תרגום, פידבק ויזואלי, הנחיות, ושמירה על חוויית משתמש חלקה.

### תאריכים עיקריים
- פיתוח ראשוני: 2024-05
- שיפורי UX, תיקוני באגים, תיעוד: 2024-06

---

## Next Step
- Start building the new `