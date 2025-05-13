import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../ui/widgets/screenshot_mode_dialog.dart';
import 'screenshot_service.dart';
import 'screen_region_selector_service.dart';

/// מנהל צילומי מסך
/// מאחד את כל הפונקציונליות של צילומי מסך תחת שירות אחד
/// ומפריד את הלוגיקה מה-UI
class ScreenshotManager {
  final ScreenshotService _screenshotService;
  final ScreenRegionSelectorService _regionSelectorService;

  /// בנאי עם dependency injection של השירותים
  ScreenshotManager({
    ScreenshotService? screenshotService,
    ScreenRegionSelectorService? regionSelectorService,
  }) : _screenshotService = screenshotService ?? ScreenshotService(),
       _regionSelectorService =
           regionSelectorService ??
           ScreenRegionSelectorService(
             screenshotService ?? ScreenshotService(),
           );

  /// מציג דיאלוג לבחירת סוג צילום המסך ומבצע את הצילום המתאים
  Future<ScreenshotResult?> takeScreenshot(
    BuildContext context, {
    GlobalKey? appKey,
  }) async {
    try {
      // הצגת דיאלוג בחירת סוג צילום המסך
      final captureMode = await showDialog<String>(
        context: context,
        builder: (context) => const ScreenshotModeDialog(),
      );

      // אם המשתמש ביטל את הפעולה
      if (captureMode == null) return null;

      // קבלת צילום המסך בהתאם לבחירה
      Uint8List? bytes;
      String caption = "צילמתי את המסך";

      switch (captureMode) {
        case 'entire_screen':
          bytes = await _screenshotService.captureEntireScreen();
          caption = "צילמתי את כל המסך שלך. מה תרצה לדעת על זה?";
          break;
        case 'region':
          // שימוש בשירות בחירת אזור מסך
          bytes = await _regionSelectorService.selectRegion(context);
          caption = "צילמתי את האזור שבחרת. מה תרצה לדעת על זה?";
          break;
        case 'window':
          bytes = await _screenshotService.captureWindow();
          caption = "צילמתי את החלון שבחרת. מה תרצה לדעת על זה?";
          break;
        case 'current_app':
          // וידוא שיש מפתח לצילום האפליקציה הנוכחית
          if (appKey == null) {
            return ScreenshotResult(
              success: false,
              caption: "לא ניתן לצלם את האפליקציה - חסר מפתח גישה לממשק",
            );
          }
          bytes = await _screenshotService.captureWidget(appKey);
          caption = "צילמתי את האפליקציה הנוכחית. מה תרצה לדעת על זה?";
          break;
      }

      // בדיקה האם הצילום הצליח
      if (bytes == null) {
        return ScreenshotResult(
          success: false,
          caption: "לא הצלחתי לצלם את המסך. נסה שוב או בחר אפשרות אחרת.",
        );
      }

      // החזרת תוצאת הצילום המוצלחת
      return ScreenshotResult(success: true, bytes: bytes, caption: caption);
    } catch (e) {
      print('Error in takeScreenshot: $e');
      return ScreenshotResult(
        success: false,
        caption: "אירעה שגיאה בצילום המסך: $e",
      );
    }
  }

  /// שמירת צילום מסך לקובץ
  Future<String?> saveScreenshot(Uint8List bytes, {String? filename}) {
    return _screenshotService.saveScreenshot(bytes, filename: filename);
  }
}

/// מחלקה המכילה את תוצאות צילום המסך
class ScreenshotResult {
  final bool success;
  final Uint8List? bytes;
  final String caption;

  ScreenshotResult({required this.success, this.bytes, required this.caption});
}
