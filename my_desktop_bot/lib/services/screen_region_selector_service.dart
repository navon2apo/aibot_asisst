import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'screenshot_service.dart';

/// שירות לבחירת אזור על המסך
/// מאפשר למשתמש לבחור אזור ספציפי על המסך באמצעות ממשק גרפי
class ScreenRegionSelectorService {
  final ScreenshotService _screenshotService;

  ScreenRegionSelectorService(this._screenshotService);

  /// פותח דיאלוג לבחירת אזור צילום על המסך
  /// מחזיר את נתוני התמונה של האזור הנבחר
  Future<Uint8List?> selectRegion(BuildContext context) async {
    // קודם מבצע צילום מסך מלא
    final fullScreenshot = await _screenshotService.captureEntireScreen();
    if (fullScreenshot == null) {
      return null;
    }

    // מציג את הדיאלוג לבחירת אזור
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => RegionSelectorDialog(screenshot: fullScreenshot),
    );

    // אם המשתמש ביטל את הבחירה
    if (result == null) {
      return null;
    }

    // מחזיר את האזור הנבחר
    return await _screenshotService.cropScreenshot(
      fullScreenshot,
      result['x'],
      result['y'],
      result['width'],
      result['height'],
    );
  }
}

/// דיאלוג המאפשר למשתמש לבחור אזור על המסך באמצעות גרירה
class RegionSelectorDialog extends StatefulWidget {
  final Uint8List screenshot;

  const RegionSelectorDialog({super.key, required this.screenshot});

  @override
  _RegionSelectorDialogState createState() => _RegionSelectorDialogState();
}

class _RegionSelectorDialogState extends State<RegionSelectorDialog> {
  Offset? _startPoint;
  Offset? _endPoint;
  bool _isDragging = false;
  Size? _imageSize;
  final GlobalKey _imageKey = GlobalKey();
  late int _originalWidth;
  late int _originalHeight;
  // מוסיף דגל שמציין אם הבחירה הושלמה
  bool _selectionCompleted = false;

  @override
  void initState() {
    super.initState();
    // קבלת ממדי התמונה המקורית
    _getOriginalImageSize();
  }

  // פונקציה לקבלת גודל התמונה המקורית
  void _getOriginalImageSize() async {
    final memImage = await decodeImageFromList(widget.screenshot);
    setState(() {
      _originalWidth = memImage.width;
      _originalHeight = memImage.height;
    });
  }

  // חישוב יחסי גודל בין התמונה המקורית לתמונה המוצגת
  Size _getDisplaySize() {
    if (_imageKey.currentContext == null) {
      return Size(0, 0);
    }
    final renderBox = _imageKey.currentContext!.findRenderObject() as RenderBox;
    return renderBox.size;
  }

  // המרת קואורדינטות מהממשק לקואורדינטות בתמונה המקורית
  Map<String, int> _calculateOriginalCoordinates(Rect displayRect) {
    if (_originalWidth == 0 || _originalHeight == 0) {
      print('Warning: Original image dimensions not available yet');
      return {
        'x': displayRect.left.toInt(),
        'y': displayRect.top.toInt(),
        'width': displayRect.width.toInt(),
        'height': displayRect.height.toInt(),
      };
    }

    final displaySize = _getDisplaySize();

    if (displaySize.width == 0 || displaySize.height == 0) {
      print('Warning: Display size not available yet');
      return {
        'x': displayRect.left.toInt(),
        'y': displayRect.top.toInt(),
        'width': displayRect.width.toInt(),
        'height': displayRect.height.toInt(),
      };
    }

    // חישוב הגבולות של התמונה בתוך התצוגה
    final renderBox = _imageKey.currentContext!.findRenderObject() as RenderBox;
    final imagePosition = renderBox.localToGlobal(Offset.zero);

    // חישוב האזור שבו התמונה מוצגת בפועל (בגלל fit: BoxFit.contain)
    double displayImageWidth = displaySize.width;
    double displayImageHeight = displaySize.height;

    // אם היחס של התמונה המקורית שונה מהתצוגה, חישוב האזור האמיתי שתופסת התמונה
    double imageAspectRatio = _originalWidth / _originalHeight;
    double displayAspectRatio = displaySize.width / displaySize.height;

    double imageDisplayWidth, imageDisplayHeight;
    double offsetX = 0, offsetY = 0;

    // התאמת גודל התמונה המוצגת בהתאם ליחס שלה
    if (imageAspectRatio > displayAspectRatio) {
      // התמונה רחבה יותר - ממלאת את הרוחב ויש רווח למעלה ולמטה
      imageDisplayWidth = displaySize.width;
      imageDisplayHeight = displaySize.width / imageAspectRatio;
      offsetY = (displaySize.height - imageDisplayHeight) / 2;
    } else {
      // התמונה גבוהה יותר - ממלאת את הגובה ויש רווח בצדדים
      imageDisplayHeight = displaySize.height;
      imageDisplayWidth = displaySize.height * imageAspectRatio;
      offsetX = (displaySize.width - imageDisplayWidth) / 2;
    }

    // חישוב הקואורדינטות ביחס לתמונה המוצגת, תוך התחשבות באופסטים
    double relativeX = displayRect.left - offsetX;
    double relativeY = displayRect.top - offsetY;

    // מגביל את הקואורדינטות לתחום התמונה המוצגת
    relativeX = relativeX.clamp(0.0, imageDisplayWidth);
    relativeY = relativeY.clamp(0.0, imageDisplayHeight);

    // חישוב הרוחב והגובה ביחס לתמונה המוצגת
    double relativeWidth = displayRect.width;
    double relativeHeight = displayRect.height;

    // מגביל את הבחירה לתחום התמונה המוצגת
    if (relativeX + relativeWidth > imageDisplayWidth) {
      relativeWidth = imageDisplayWidth - relativeX;
    }
    if (relativeY + relativeHeight > imageDisplayHeight) {
      relativeHeight = imageDisplayHeight - relativeY;
    }

    // חישוב יחס הגדלה/הקטנה
    final scaleX = _originalWidth / imageDisplayWidth;
    final scaleY = _originalHeight / imageDisplayHeight;

    // המרת הקואורדינטות לגודל התמונה המקורית
    final originalX = (relativeX * scaleX).toInt();
    final originalY = (relativeY * scaleY).toInt();
    final originalWidth = (relativeWidth * scaleX).toInt();
    final originalHeight = (relativeHeight * scaleY).toInt();

    // לוגים מפורטים
    print('====== Debug Crop Coordinates ======');
    print('Original image: $_originalWidth x $_originalHeight');
    print('Display size: ${displaySize.width} x ${displaySize.height}');
    print(
      'Image display area: $imageDisplayWidth x $imageDisplayHeight, offset: $offsetX, $offsetY',
    );
    print(
      'Selection on screen: ${displayRect.left}, ${displayRect.top}, ${displayRect.width}, ${displayRect.height}',
    );
    print(
      'Relative to image: $relativeX, $relativeY, $relativeWidth, $relativeHeight',
    );
    print('Scale factors: $scaleX, $scaleY');
    print(
      'Original coordinates: $originalX, $originalY, $originalWidth, $originalHeight',
    );
    print('====================================');

    return {
      'x': originalX,
      'y': originalY,
      'width': originalWidth,
      'height': originalHeight,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54,
      body: Stack(
        children: [
          // תמונת הרקע (צילום המסך המלא)
          Positioned.fill(
            child: Image.memory(
              widget.screenshot,
              key: _imageKey,
              fit: BoxFit.contain,
            ),
          ),

          // אזור הבחירה
          Positioned.fill(
            child: GestureDetector(
              onPanStart: _handlePanStart,
              onPanUpdate: _handlePanUpdate,
              onPanEnd: _handlePanEnd,
              child: CustomPaint(
                painter: SelectionPainter(
                  startPoint: _startPoint,
                  endPoint: _endPoint,
                ),
              ),
            ),
          ),

          // הנחיות למשתמש
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _isDragging || _selectionCompleted
                    ? "אזור נבחר. לחץ על אישור לחיתוך או בחר אזור חדש."
                    : "גרור את העכבר לבחירת אזור לצילום. לחץ ESC לביטול.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),

          // כפתורים
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _handleCancel,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text("ביטול"),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _canConfirm() ? _handleConfirm : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: Text("אישור"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handlePanStart(DragStartDetails details) {
    print("Pan start at: ${details.localPosition}");
    setState(() {
      // איפוס הבחירה הקודמת אם קיימת
      _selectionCompleted = false;
      _startPoint = details.localPosition;
      _endPoint = details.localPosition;
      _isDragging = true;
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_isDragging) {
      setState(() {
        _endPoint = details.localPosition;
      });
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    print("Pan end with start: $_startPoint, end: $_endPoint");
    if (_startPoint != null && _endPoint != null) {
      final width = (_endPoint!.dx - _startPoint!.dx).abs();
      final height = (_endPoint!.dy - _startPoint!.dy).abs();

      // אם האזור הנבחר מספיק גדול, מסמנים את הבחירה כהושלמה
      if (width > 10 && height > 10) {
        setState(() {
          _isDragging = false;
          _selectionCompleted = true; // מסמן שהבחירה הושלמה
        });
        print(
          "Selection completed: ${_startPoint!.dx},${_startPoint!.dy} to ${_endPoint!.dx},${_endPoint!.dy}",
        );
      } else {
        // אם האזור קטן מדי, מבטלים את הבחירה
        setState(() {
          _isDragging = false;
          _selectionCompleted = false;
          // לא מאפסים את הנקודות כדי שהן יישארו מוצגות
        });
        print("Selection too small, not completed");
      }
    } else {
      setState(() {
        _isDragging = false;
      });
    }
  }

  bool _canConfirm() {
    if (_startPoint == null || _endPoint == null) return false;
    final width = (_endPoint!.dx - _startPoint!.dx).abs();
    final height = (_endPoint!.dy - _startPoint!.dy).abs();
    // מאפשר אישור רק אם האזור גדול מספיק
    return width > 10 && height > 10;
  }

  void _handleConfirm() {
    if (!_canConfirm()) return;

    // חישוב המלבן הנבחר
    final left =
        _startPoint!.dx < _endPoint!.dx ? _startPoint!.dx : _endPoint!.dx;
    final top =
        _startPoint!.dy < _endPoint!.dy ? _startPoint!.dy : _endPoint!.dy;
    final right =
        _startPoint!.dx > _endPoint!.dx ? _startPoint!.dx : _endPoint!.dx;
    final bottom =
        _startPoint!.dy > _endPoint!.dy ? _startPoint!.dy : _endPoint!.dy;

    final displayRect = Rect.fromLTRB(left, top, right, bottom);

    // המרת הקואורדינטות לגודל התמונה המקורית
    final originalCoords = _calculateOriginalCoordinates(displayRect);

    // החזרת הקואורדינטות המקוריות
    Navigator.of(context).pop(originalCoords);
  }

  void _handleCancel() {
    Navigator.of(context).pop();
  }
}

/// צייר מותאם אישית שמציג את אזור הבחירה
class SelectionPainter extends CustomPainter {
  final Offset? startPoint;
  final Offset? endPoint;

  SelectionPainter({this.startPoint, this.endPoint});

  @override
  void paint(Canvas canvas, Size size) {
    if (startPoint == null || endPoint == null) return;

    // צייר שטח כהה מסביב לאזור הנבחר
    final selectionRect = Rect.fromPoints(startPoint!, endPoint!);

    // מלבן חיצוני (כל המסך)
    final outerPaint =
        Paint()
          ..color = Colors.black.withOpacity(0.5)
          ..style = PaintingStyle.fill;

    // צייר ארבעה מלבנים מסביב לאזור הנבחר
    // מלבן עליון
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, selectionRect.top),
      outerPaint,
    );

    // מלבן שמאלי
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        selectionRect.top,
        selectionRect.left,
        selectionRect.height,
      ),
      outerPaint,
    );

    // מלבן ימני
    canvas.drawRect(
      Rect.fromLTWH(
        selectionRect.right,
        selectionRect.top,
        size.width - selectionRect.right,
        selectionRect.height,
      ),
      outerPaint,
    );

    // מלבן תחתון
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        selectionRect.bottom,
        size.width,
        size.height - selectionRect.bottom,
      ),
      outerPaint,
    );

    // צייר מסגרת לאזור הנבחר
    final borderPaint =
        Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    canvas.drawRect(selectionRect, borderPaint);

    // מידות האזור הנבחר
    final textPainter = TextPainter(
      text: TextSpan(
        text:
            '${selectionRect.width.toInt()} x ${selectionRect.height.toInt()}',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          backgroundColor: Colors.black54,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // מציג את המידות מעל האזור הנבחר אם יש מספיק מקום
    final textX =
        selectionRect.left + (selectionRect.width - textPainter.width) / 2;
    final textY =
        selectionRect.top > 20
            ? selectionRect.top - 20
            : selectionRect.bottom + 5;

    textPainter.paint(canvas, Offset(textX, textY));
  }

  @override
  bool shouldRepaint(covariant SelectionPainter oldDelegate) {
    return oldDelegate.startPoint != startPoint ||
        oldDelegate.endPoint != endPoint;
  }
}
