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

## Next Step
- Start building the new `