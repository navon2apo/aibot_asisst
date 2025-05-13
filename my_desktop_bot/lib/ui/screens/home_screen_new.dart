import 'package:flutter/material.dart';
import '../../controllers/chat_controller.dart';
import '../widgets/floating_menu.dart';
import '../widgets/window_title_bar.dart';
import '../widgets/settings_dialog.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/window_size_display.dart';
import '../widgets/screenshot_mode_dialog.dart';
import 'dart:typed_data';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/scheduler.dart';
import '../../models/chat_message.dart';

/// דף הבית החדש - UI בלבד, כל הלוגיקה עוברת לקונטרולר
class HomeScreenNew extends StatefulWidget {
  final ChatController chatController;
  const HomeScreenNew({Key? key, required this.chatController})
    : super(key: key);

  @override
  State<HomeScreenNew> createState() => _HomeScreenNewState();
}

class _HomeScreenNewState extends State<HomeScreenNew> {
  @override
  void initState() {
    super.initState();
    widget.chatController.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.chatController.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white.withOpacity(
          0.5,
        ), // הוספת שקיפות לרקע הלבן
        body: Column(
          children: [
            // כאן מוסיפים את סרגל הכותרת המותאם אישית
            WindowTitleBar(
              onSettingsPressed: _showAPISettingsDialog,
              onSizeDisplayToggle: _toggleWindowSizeDisplay,
              showSizeDisplay: widget.chatController.showWindowSize,
            ),
            // שימוש ב-Expanded כדי שהתוכן ימלא את שאר החלון
            Expanded(
              child: RepaintBoundary(
                key: widget.chatController.globalKey,
                child: Stack(
                  children: <Widget>[
                    // Main content - שינוי רקע עם שקיפות
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.white.withOpacity(0.4), // רקע שקוף יותר
                    ),

                    // Chat window - עדכון למיקום דינמי
                    if (widget.chatController.isChatVisible)
                      Positioned(
                        right: widget.chatController.chatPosition.dx,
                        top: widget.chatController.chatPosition.dy,
                        child: AnimatedBuilder(
                          animation: widget.chatController.animation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: widget.chatController.animation.value,
                              child: Container(
                                width: widget.chatController.chatWidth,
                                height: widget.chatController.chatHeight,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(
                                    0.7,
                                  ), // רקע עם שקיפות בינונית
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 8,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    Column(
                                      children: [
                                        // Chat header - עדיין ניתן לגרירה בחלון הצ'אט
                                        GestureDetector(
                                          onPanUpdate: (details) {
                                            setState(() {
                                              widget
                                                  .chatController
                                                  .chatPosition = Offset(
                                                widget
                                                        .chatController
                                                        .chatPosition
                                                        .dx -
                                                    details.delta.dx,
                                                widget
                                                        .chatController
                                                        .chatPosition
                                                        .dy +
                                                    details.delta.dy,
                                              );
                                            });
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.deepPurple.shade200,
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(16),
                                                topRight: Radius.circular(16),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    SizedBox(width: 4),
                                                    Text(
                                                      widget
                                                                  .chatController
                                                                  .currentSessionId !=
                                                              null
                                                          ? (widget.chatController
                                                                      .getSessionName(
                                                                        widget
                                                                            .chatController
                                                                            .currentSessionId!,
                                                                      ) !=
                                                                  ''
                                                              ? widget
                                                                  .chatController
                                                                  .getSessionName(
                                                                    widget
                                                                        .chatController
                                                                        .currentSessionId!,
                                                                  )
                                                              : 'צ׳אט ללא שם')
                                                          : 'צ׳אט ללא שם',
                                                      style:
                                                          GoogleFonts.assistant(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 16,
                                                            color:
                                                                Colors.black87,
                                                          ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    GestureDetector(
                                                      onTap: _toggleAlwaysOnTop,
                                                      child: Tooltip(
                                                        message: 'תמיד בחזית',
                                                        child: Icon(
                                                          widget
                                                                  .chatController
                                                                  .isAlwaysOnTop
                                                              ? Icons.push_pin
                                                              : Icons
                                                                  .push_pin_outlined,
                                                          size: 16,
                                                          color:
                                                              widget
                                                                      .chatController
                                                                      .isAlwaysOnTop
                                                                  ? Colors
                                                                      .deepPurple
                                                                  : Colors
                                                                      .black54,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    IconButton(
                                                      icon: Icon(
                                                        Icons
                                                            .add_circle_outline,
                                                        size: 18,
                                                        color: Colors.black54,
                                                      ),
                                                      onPressed:
                                                          () =>
                                                              _showSessionsMenu(
                                                                context,
                                                              ),
                                                      padding: EdgeInsets.zero,
                                                      tooltip: 'ניהול שיחות',
                                                      constraints:
                                                          BoxConstraints(),
                                                    ),
                                                    SizedBox(width: 8),
                                                    IconButton(
                                                      icon: Icon(
                                                        Icons.close,
                                                        size: 18,
                                                        color: Colors.black54,
                                                      ),
                                                      onPressed: _toggleChat,
                                                      padding: EdgeInsets.zero,
                                                      tooltip: 'סגור',
                                                      constraints:
                                                          BoxConstraints(),
                                                    ),
                                                    SizedBox(width: 8),
                                                    IconButton(
                                                      icon: Icon(
                                                        Icons.delete,
                                                        size: 18,
                                                        color: Colors.black54,
                                                      ),
                                                      onPressed:
                                                          _showClearHistoryConfirmation,
                                                      padding: EdgeInsets.zero,
                                                      tooltip: 'נקה היסטוריה',
                                                      constraints:
                                                          BoxConstraints(),
                                                    ),
                                                    SizedBox(width: 8),
                                                    IconButton(
                                                      icon: Icon(
                                                        Icons.settings,
                                                        size: 18,
                                                        color: Colors.black54,
                                                      ),
                                                      onPressed:
                                                          _showAPISettingsDialog,
                                                      padding: EdgeInsets.zero,
                                                      tooltip: 'הגדרות',
                                                      constraints:
                                                          BoxConstraints(),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        // Chat messages
                                        Expanded(
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 15,
                                              vertical: 10,
                                            ),
                                            child: ListView.builder(
                                              controller:
                                                  widget
                                                      .chatController
                                                      .scrollController,
                                              itemCount:
                                                  widget
                                                      .chatController
                                                      .chatHistory
                                                      .length,
                                              itemBuilder: (context, index) {
                                                final message =
                                                    widget
                                                        .chatController
                                                        .chatHistory[index];
                                                return ChatBubble(
                                                  message: message,
                                                );
                                              },
                                            ),
                                          ),
                                        ),

                                        // Typing indicator
                                        if (widget
                                            .chatController
                                            .isAssistantTyping)
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 10,
                                            ),
                                            alignment: Alignment.centerRight,
                                            child: Row(
                                              children: [
                                                Text(
                                                  'העוזר מקליד...',
                                                  style: GoogleFonts.assistant(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(Colors.deepPurple),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                        // Chat input
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 15,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.only(
                                              bottomLeft: Radius.circular(16),
                                              bottomRight: Radius.circular(16),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black12,
                                                blurRadius: 5,
                                                offset: Offset(0, -2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            children: [
                                              // אייקון מיקרופון בתחתית
                                              SizedBox(width: 5),
                                              IconButton(
                                                icon: Icon(
                                                  widget
                                                          .chatController
                                                          .isRecording
                                                      ? Icons.stop_circle
                                                      : Icons.mic_none,
                                                  color:
                                                      widget
                                                              .chatController
                                                              .isRecording
                                                          ? Colors.red
                                                          : Colors.grey,
                                                  size: 24,
                                                ),
                                                onPressed: toggleAudioRecording,
                                                padding: EdgeInsets.zero,
                                              ),
                                              // מקום להקלדה
                                              Expanded(
                                                child: TextField(
                                                  controller:
                                                      widget
                                                          .chatController
                                                          .messageController,
                                                  maxLines: null,
                                                  minLines: 1,
                                                  textInputAction:
                                                      TextInputAction.newline,
                                                  keyboardType:
                                                      TextInputType.multiline,
                                                  decoration: InputDecoration(
                                                    hintText:
                                                        'כתיבת הודעה על...',
                                                    border: InputBorder.none,
                                                    contentPadding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 15,
                                                          vertical: 8,
                                                        ),
                                                  ),
                                                  onSubmitted: _handleSubmit,
                                                ),
                                              ),
                                              // אייקונים נוספים
                                              IconButton(
                                                icon: Icon(
                                                  Icons.more_vert,
                                                  color: Colors.grey,
                                                  size: 24,
                                                ),
                                                onPressed: () {
                                                  // פתיחת תפריט אפשרויות נוספות
                                                  showMenu(
                                                    context: context,
                                                    position:
                                                        RelativeRect.fromLTRB(
                                                          0,
                                                          0,
                                                          0,
                                                          0,
                                                        ),
                                                    items: [
                                                      PopupMenuItem(
                                                        value: 'uploadImage',
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              Icons.image,
                                                              color:
                                                                  Colors.blue,
                                                            ),
                                                            SizedBox(width: 10),
                                                            Text('העלה תמונה'),
                                                          ],
                                                        ),
                                                      ),
                                                      PopupMenuItem(
                                                        value: 'screenshot',
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              Icons.camera_alt,
                                                              color:
                                                                  Colors.green,
                                                            ),
                                                            SizedBox(width: 10),
                                                            Text('צלם מסך'),
                                                          ],
                                                        ),
                                                      ),
                                                      // תת-תפריט לאפשרויות נוספות של צילום מסך
                                                      PopupMenuItem(
                                                        enabled: false,
                                                        child: Text(
                                                          'אפשרויות צילום מסך נוספות:',
                                                          style: TextStyle(
                                                            color:
                                                                Colors
                                                                    .grey[700],
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ),
                                                      PopupMenuItem(
                                                        value:
                                                            'screenshot_region',
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              Icons.crop,
                                                              color:
                                                                  Colors.orange,
                                                            ),
                                                            SizedBox(width: 10),
                                                            Text(
                                                              'בחר אזור לצילום',
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      PopupMenuItem(
                                                        value:
                                                            'screenshot_window',
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              Icons.window,
                                                              color:
                                                                  Colors.blue,
                                                            ),
                                                            SizedBox(width: 10),
                                                            Text('צלם חלון'),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ).then((value) async {
                                                    if (value ==
                                                        'uploadImage') {
                                                      uploadImage();
                                                    } else if (value ==
                                                            'screenshot' ||
                                                        value ==
                                                            'screenshot_region' ||
                                                        value ==
                                                            'screenshot_window') {
                                                      // כל צילום מסך עובר דרך ChatController
                                                      await widget
                                                          .chatController
                                                          .takeScreenshot(
                                                            context,
                                                            asUser: false,
                                                          );
                                                    }
                                                  });
                                                },
                                                padding: EdgeInsets.zero,
                                              ),
                                              SizedBox(width: 10),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.send,
                                                  color: Colors.deepPurple,
                                                  size: 24,
                                                ),
                                                onPressed:
                                                    () => _handleSubmit(
                                                      widget
                                                          .chatController
                                                          .messageController
                                                          .text,
                                                    ),
                                                padding: EdgeInsets.zero,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    // כפתור שינוי גודל
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: GestureDetector(
                                        onPanStart: (details) {
                                          setState(() {
                                            widget.chatController.isResizing =
                                                true;
                                          });
                                        },
                                        onPanUpdate: (details) {
                                          setState(() {
                                            // מגביל את הגודל המינימלי
                                            widget
                                                .chatController
                                                .chatWidth = (widget
                                                        .chatController
                                                        .chatWidth +
                                                    details.delta.dx)
                                                .clamp(300.0, 600.0);
                                            widget
                                                .chatController
                                                .chatHeight = (widget
                                                        .chatController
                                                        .chatHeight +
                                                    details.delta.dy)
                                                .clamp(400.0, 800.0);
                                          });
                                        },
                                        onPanEnd: (details) {
                                          setState(() {
                                            widget.chatController.isResizing =
                                                false;
                                          });
                                        },
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: Colors.deepPurple
                                                .withOpacity(0.3),
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(10),
                                              bottomRight: Radius.circular(20),
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.drag_handle,
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    // Floating buttons
                    FloatingMenu(
                      position: widget.chatController.position,
                      onPositionChanged: (newPosition) {
                        setState(() {
                          widget.chatController.position = newPosition;
                        });
                      },
                      onChatToggle: _toggleChat,
                      onScreenshot: takeScreenshot,
                      onSettings: _showAPISettingsDialog,
                      onVoiceCommand:
                          widget.chatController.isListening
                              ? _stopListening
                              : _startListening,
                      onImageUpload: uploadImage,
                      onAudioRecord: toggleAudioRecording,
                      isListening: widget.chatController.isListening,
                      isRecording: widget.chatController.isRecording,
                    ),

                    // הודעה זמנית אם קיימת
                    if (widget.chatController.temporaryMessage != null)
                      Positioned(
                        bottom: 80,
                        right: 20,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          constraints: BoxConstraints(maxWidth: 300),
                          child: Text(
                            widget.chatController.temporaryMessage!,
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void onWindowFocus() {
    // כאשר החלון מקבל פוקוס - לא עושים כלום
  }

  @override
  void onWindowBlur() {
    // כאשר החלון מאבד פוקוס - לא סוגרים את החלון
    // אם היינו רוצים לסגור את החלון היינו מוסיפים כאן קוד
  }

  @override
  void onWindowClose() async {
    // מניעת סגירת החלון - מינימייז במקום
    bool isPreventClose =
        await widget.chatController.windowManager.isPreventClose();
    if (isPreventClose) {
      await widget.chatController.windowManager.minimize();
    }
  }

  // מתודה לבדיקה של מצב Always On Top
  Future<void> _checkAlwaysOnTop() async {
    try {
      bool onTop = await widget.chatController.windowManager.isAlwaysOnTop();
      if (mounted && onTop != widget.chatController.isAlwaysOnTop) {
        setState(() {
          widget.chatController.isAlwaysOnTop = onTop;
        });
      }

      // בדיקה חוזרת כל 10 שניות
      Future.delayed(Duration(seconds: 10), _checkAlwaysOnTop);
    } catch (e) {
      print('Error checking always on top: $e');
    }
  }

  // מתודה לשליטה במצב Always On Top
  Future<void> _toggleAlwaysOnTop() async {
    try {
      await widget.chatController.windowManager.setAlwaysOnTop(
        !widget.chatController.isAlwaysOnTop,
      );

      bool newState = await widget.chatController.windowManager.isAlwaysOnTop();
      setState(() {
        widget.chatController.isAlwaysOnTop = newState;
      });

      _showTemporaryMessage(
        widget.chatController.isAlwaysOnTop
            ? "החלון יופיע תמיד מעל חלונות אחרים"
            : "החלון לא יהיה תמיד למעלה",
      );
    } catch (e) {
      print('Error toggling always on top: $e');
    }
  }

  // מתודה לטיפול בתוצאות צילום המסך
  void _handleScreenshotResult(Uint8List? bytes, String messageText) {
    if (bytes != null) {
      // TODO: להחליף ל-ChatMessage אמיתי מהמודל
      final message = null;

      setState(() {
        widget.chatController.screenshotBytes = bytes;
        widget.chatController.chatHistory.add(message);
        widget.chatController.isChatVisible = true;
        widget.chatController.animationController.forward();
      });

      _saveChatMessage(message);

      // גלילה לסוף הצ'אט
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } else {
      // TODO: להחליף ל-ChatMessage אמיתי מהמודל
      final message = null;

      setState(() {
        widget.chatController.chatHistory.add(message);
        widget.chatController.isChatVisible = true;
        widget.chatController.animationController.forward();
      });

      _saveChatMessage(message);

      // גלילה לסוף הצ'אט
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  // --- פונקציות דמה עבור כל הפונקציות החסרות ב-UI ---
  void _showAPISettingsDialog() {
    showDialog(
      context: context,
      builder:
          (context) => SettingsDialog(
            initialSettings: widget.chatController.apiSettings,
            onSave: (newSettings) async {
              print(
                '[DEBUG] onSave (SettingsDialog): saving newSettings = \\n${newSettings.toJson()}',
              );
              widget.chatController.updateSettings(newSettings);
              // עדכן את כל השירותים עם ההגדרות החדשות
              widget.chatController.gptService.updateSettings(newSettings);
              widget.chatController.speechService.updateSettings(newSettings);
              widget.chatController.whisperService.updateSettings(newSettings);
              // שמור את ההגדרות ל-repo (פרסיסטנטי)
              widget.chatController.chatRepo.saveApiSettings(newSettings);
              setState(() {});
              // אפשר להוסיף הודעת הצלחה לצ'אט
              widget.chatController.chatHistory.add(
                ChatMessage(
                  text:
                      "הגדרות ה-API עודכנו בהצלחה! אתה יכול להתחיל לשאול שאלות.",
                  isUser: false,
                  timestamp: DateTime.now(),
                ),
              );
              widget.chatController.notifyListeners();
            },
          ),
    );
  }

  void _toggleWindowSizeDisplay() {
    /* TODO: implement */
  }
  void _showSessionsMenu(BuildContext context) async {
    final TextEditingController nameController = TextEditingController();
    String? editingSessionId;
    final Map<String, TextEditingController> editControllers = {};
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('ניהול שיחות'),
              content: SizedBox(
                width: 350,
                height: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: widget.chatController.chatSessions.length,
                        itemBuilder: (context, index) {
                          if (index >=
                              widget.chatController.chatSessions.length)
                            return SizedBox.shrink();
                          final sessionId =
                              widget.chatController.chatSessions[index];
                          final isSelected =
                              sessionId ==
                              widget.chatController.currentSessionId;
                          final sessionName = widget.chatController
                              .getSessionName(sessionId);
                          editControllers.putIfAbsent(
                            sessionId,
                            () => TextEditingController(text: sessionName),
                          );
                          return ListTile(
                            title:
                                editingSessionId == sessionId
                                    ? Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller:
                                                editControllers[sessionId],
                                            autofocus: true,
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.check,
                                            color: Colors.green,
                                          ),
                                          onPressed: () {
                                            widget.chatController
                                                .setSessionName(
                                                  sessionId,
                                                  editControllers[sessionId]!
                                                      .text
                                                      .trim(),
                                                );
                                            setStateDialog(() {
                                              editingSessionId = null;
                                            });
                                          },
                                        ),
                                      ],
                                    )
                                    : Text(
                                      sessionName.isNotEmpty
                                          ? sessionName
                                          : 'שיחה ${index + 1}',
                                    ),
                            selected: isSelected,
                            onTap: () {
                              final sessionId =
                                  widget.chatController.chatSessions[index];
                              widget.chatController.switchSession(sessionId);
                              Navigator.pop(context);
                            },
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    setStateDialog(() {
                                      editingSessionId = sessionId;
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    final sessions =
                                        widget.chatController.chatSessions;
                                    final wasSelected =
                                        widget
                                            .chatController
                                            .currentSessionId ==
                                        sessionId;
                                    widget.chatController.chatRepo
                                        .deleteSession(sessionId);
                                    widget.chatController.deleteSessionName(
                                      sessionId,
                                    );
                                    sessions.remove(sessionId);
                                    if (wasSelected) {
                                      if (sessions.isNotEmpty) {
                                        final newId = sessions.first;
                                        widget.chatController.switchSession(
                                          newId,
                                        );
                                      } else {
                                        widget.chatController.currentSessionId =
                                            null;
                                        widget.chatController.chatHistory = [];
                                        widget.chatController.notifyListeners();
                                      }
                                    }
                                    setStateDialog(() {});
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Divider(),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: nameController,
                            decoration: InputDecoration(
                              hintText: 'שם לשיחה חדשה',
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.add_circle,
                            color: Colors.deepPurple,
                          ),
                          onPressed: () {
                            String name = nameController.text.trim();
                            if (name.isEmpty) {
                              name = 'שיחה חדשה';
                            }
                            widget.chatController.createNewSession(name);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _toggleChat() {
    setState(() {
      widget.chatController.isChatVisible =
          !widget.chatController.isChatVisible;
      if (widget.chatController.isChatVisible) {
        // בכל פתיחה, קבע מיקום וגודל נוחים
        widget.chatController.chatWidth = 340;
        widget.chatController.chatHeight = 400;
        widget.chatController.chatPosition = Offset(30, 40);
      }
    });
  }

  void _showClearHistoryConfirmation() {
    // TODO: אפשר להוסיף דיאלוג אישור, כרגע קריאה ישירה
    widget.chatController.clearHistory();
  }

  void toggleAudioRecording() {
    widget.chatController.toggleAudioRecording();
  }

  void _handleSubmit([String? text]) async {
    await widget.chatController.handleSubmit(text);
  }

  void uploadImage() {
    widget.chatController.uploadImage();
  }

  void takeScreenshot() {
    // קריאה אחידה דרך ChatController בלבד (כ'הודעת עוזר')
    widget.chatController.takeScreenshot(context, asUser: false);
    setState(() {
      widget.chatController.isChatVisible = true;
    });
    // גלילה אוטומטית לסוף הצ'אט אחרי שה-UI התעדכן
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.chatController.scrollToBottom();
    });
  }

  void _stopListening() {
    /* TODO: implement */
  }
  void _startListening() {
    /* TODO: implement */
  }
  void _showTemporaryMessage(String message) {
    /* TODO: implement */
  }
  void _saveChatMessage(dynamic message) {
    /* TODO: implement */
  }
  void _scrollToBottom() {
    /* TODO: implement */
  }
}

// מחלקת דמה עבור TestVSync
class TestVSync implements TickerProvider {
  const TestVSync();
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}
