import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:screenshot/screenshot.dart';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'package:image/image.dart' as img;

/// שירות צילום מסך מתקדם
/// מאפשר צילום מסך בדרכים שונות:
/// 1. צילום מסך מלא
/// 2. בחירת אזור לצילום
/// 3. צילום חלון ספציפי
/// 4. צילום של רכיב ספציפי בתוך האפליקציה
class ScreenshotService {
  // יוצר controller עבור ספריית screenshot
  final ScreenshotController _screenshotController = ScreenshotController();

  // צילום מסך של ווידג'ט ספציפי (עבור תמיכה בגרסאות קודמות)
  Future<Uint8List?> captureWidget(GlobalKey key) async {
    try {
      if (key.currentContext == null) {
        print('Error: No context found for the given key');
        return null;
      }

      RenderRepaintBoundary? boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        print('Error: Could not find RenderRepaintBoundary');
        return null;
      }

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Error capturing widget: $e');
      return null;
    }
  }

  // צילום מסך של כל המסך בעזרת Windows API באופן אמיתי
  Future<Uint8List?> captureEntireScreen() async {
    try {
      // מינימיזציה של האפליקציה שלנו כדי שנוכל לצלם את מה שמאחוריה
      // מאחזר את החלון בפוקוס הנוכחי (אמור להיות האפליקציה שלנו)
      final hwnd = GetForegroundWindow();
      ShowWindow(hwnd, SW_MINIMIZE);

      // המתנה קצרה כדי לאפשר למסך להתעדכן
      await Future.delayed(const Duration(milliseconds: 300));

      // מקבל את גודל המסך
      final screenWidth = GetSystemMetrics(SM_CXSCREEN);
      final screenHeight = GetSystemMetrics(SM_CYSCREEN);

      // יוצר DC למסך
      final hdcScreen = GetDC(NULL);
      final hdcMemory = CreateCompatibleDC(hdcScreen);
      final hBitmap = CreateCompatibleBitmap(
        hdcScreen,
        screenWidth,
        screenHeight,
      );
      final oldBitmap = SelectObject(hdcMemory, hBitmap);

      // צילום המסך באמצעות BitBlt
      BitBlt(
        hdcMemory,
        0,
        0,
        screenWidth,
        screenHeight,
        hdcScreen,
        0,
        0,
        SRCCOPY,
      );

      // יצירת מידע על הביטמאפ
      final bi = calloc<BITMAPINFO>();
      bi.ref.bmiHeader.biSize = sizeOf<BITMAPINFOHEADER>();
      bi.ref.bmiHeader.biWidth = screenWidth;
      bi.ref.bmiHeader.biHeight = -screenHeight; // שלילי לכיוון הנכון
      bi.ref.bmiHeader.biPlanes = 1;
      bi.ref.bmiHeader.biBitCount = 32;
      bi.ref.bmiHeader.biCompression = BI_RGB;

      // הקצאת זיכרון לפיקסלים
      final bitmapSize = screenWidth * screenHeight * 4;
      final bits = calloc<Uint8>(bitmapSize);

      // קבלת נתוני הביטמאפ
      GetDIBits(hdcMemory, hBitmap, 0, screenHeight, bits, bi, DIB_RGB_COLORS);

      // המרה ל-Uint8List
      final bytes = Uint8List(bitmapSize);
      for (int i = 0; i < bitmapSize; i++) {
        bytes[i] = bits[i];
      }

      // שחרור משאבים
      SelectObject(hdcMemory, oldBitmap);
      DeleteObject(hBitmap);
      DeleteDC(hdcMemory);
      ReleaseDC(NULL, hdcScreen);
      calloc.free(bi);
      calloc.free(bits);

      // החזרת החלון שלנו
      ShowWindow(hwnd, SW_RESTORE);

      // המרה לפורמט תמונה
      final image = img.Image.fromBytes(
        width: screenWidth,
        height: screenHeight,
        bytes: bytes.buffer,
        numChannels: 4,
        order: img.ChannelOrder.bgra,
      );

      // המרה ל-PNG
      final pngBytes = img.encodePng(image);
      return Uint8List.fromList(pngBytes);
    } catch (e) {
      print('Error capturing entire screen: $e');
      return null;
    }
  }

  // צילום של חלק ספציפי מהמסך (בחירת אזור)
  Future<Uint8List?> captureScreenRegion() async {
    try {
      // כדי לפשט, כרגע נצלם את המסך המלא ונחתוך ממנו חלק
      final fullScreenImage = await captureEntireScreen();
      if (fullScreenImage == null) {
        return null;
      }

      // המרה לתמונה שאפשר לערוך
      final memImage = img.decodeImage(fullScreenImage);
      if (memImage == null) {
        return null;
      }

      // חישוב אזור ברירת מחדל - חלון במרכז המסך
      final screenWidth = memImage.width;
      final screenHeight = memImage.height;

      final startX = screenWidth ~/ 4;
      final startY = screenHeight ~/ 4;
      final width = screenWidth ~/ 2;
      final height = screenHeight ~/ 2;

      // חיתוך התמונה
      final croppedImage = img.copyCrop(
        memImage,
        x: startX,
        y: startY,
        width: width,
        height: height,
      );

      // המרה חזרה ל-PNG
      final pngBytes = img.encodePng(croppedImage);
      return Uint8List.fromList(pngBytes);
    } catch (e) {
      print('Error capturing screen region: $e');
      return null;
    }
  }

  // צילום חלון ספציפי
  Future<Uint8List?> captureWindow() async {
    try {
      // פשוט נשתמש בצילום מסך מלא כרגע
      // יישום מלא של צילום חלון ספציפי יהיה מורכב יותר
      return await captureEntireScreen();
    } catch (e) {
      print('Error capturing window: $e');
      return null;
    }
  }

  // חיתוך צילום מסך לפי מיקום וגודל ספציפיים
  Future<Uint8List?> cropScreenshot(
    Uint8List screenshotBytes,
    int x,
    int y,
    int width,
    int height,
  ) async {
    try {
      print('====== cropScreenshot started ======');
      print('Input coordinates: x=$x, y=$y, width=$width, height=$height');

      // המרה לפורמט תמונה שאפשר לערוך
      final memImage = img.decodeImage(screenshotBytes);
      if (memImage == null) {
        print('Error: Failed to decode image');
        return null;
      }

      print('Original image size: ${memImage.width} x ${memImage.height}');

      // וידוא שהקואורדינטות נמצאות בתוך גבולות התמונה
      final screenWidth = memImage.width;
      final screenHeight = memImage.height;

      print('Before clamping: x=$x, y=$y, width=$width, height=$height');

      // מניעת חריגה מגבולות התמונה
      int originalX = x;
      int originalY = y;
      int originalWidth = width;
      int originalHeight = height;

      x = x.clamp(0, screenWidth - 1);
      y = y.clamp(0, screenHeight - 1);
      width = width.clamp(1, screenWidth - x);
      height = height.clamp(1, screenHeight - y);

      if (originalX != x ||
          originalY != y ||
          originalWidth != width ||
          originalHeight != height) {
        print('Coordinates were clamped to fit image borders');
      }

      print('After clamping: x=$x, y=$y, width=$width, height=$height');

      // וידוא שהגודל הוא סביר
      if (width < 10 || height < 10) {
        print('Warning: Very small crop area. Width=$width, Height=$height');
      }

      if (width > screenWidth * 0.9 && height > screenHeight * 0.9) {
        print('Warning: Very large crop area, almost the entire image');
      }

      try {
        // חיתוך התמונה
        final croppedImage = img.copyCrop(
          memImage,
          x: x,
          y: y,
          width: width,
          height: height,
        );

        print(
          'Cropped successfully to: ${croppedImage.width} x ${croppedImage.height}',
        );

        // המרה חזרה ל-PNG
        final pngBytes = img.encodePng(croppedImage);
        print('Encoded to PNG successfully, size: ${pngBytes.length} bytes');
        print('====== cropScreenshot completed ======');
        return Uint8List.fromList(pngBytes);
      } catch (cropError) {
        print('Error in cropping operation: $cropError');

        // נסיון לחיתוך עם ערכים בטוחים יותר
        print('Attempting safer crop with default values');
        final safeX = screenWidth ~/ 4;
        final safeY = screenHeight ~/ 4;
        final safeWidth = screenWidth ~/ 2;
        final safeHeight = screenHeight ~/ 2;

        final safeCroppedImage = img.copyCrop(
          memImage,
          x: safeX,
          y: safeY,
          width: safeWidth,
          height: safeHeight,
        );

        final safePngBytes = img.encodePng(safeCroppedImage);
        print('Safe crop completed: $safeX, $safeY, $safeWidth, $safeHeight');
        print('====== cropScreenshot completed with fallback ======');
        return Uint8List.fromList(safePngBytes);
      }
    } catch (e) {
      print('Error cropping screenshot: $e');
      print('====== cropScreenshot failed ======');
      return null;
    }
  }

  // שמירת תמונה למכשיר
  Future<String?> saveScreenshot(Uint8List bytes, {String? filename}) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final name =
          filename ?? 'screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$name');
      await file.writeAsBytes(bytes);

      print('Screenshot saved to: ${file.path}');
      return file.path;
    } catch (e) {
      print('Error saving screenshot: $e');
      return null;
    }
  }

  // לכידת רכיב widget בהינתן widget ספציפי
  Future<Uint8List?> captureFromWidget(Widget widget) async {
    try {
      return await _screenshotController.captureFromWidget(
        widget,
        delay: const Duration(milliseconds: 100),
      );
    } catch (e) {
      print('Error capturing from widget: $e');
      return null;
    }
  }
}
