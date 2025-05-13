import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

class WindowSizeDisplay extends StatefulWidget {
  final bool visible;

  const WindowSizeDisplay({super.key, this.visible = true});

  @override
  State<WindowSizeDisplay> createState() => _WindowSizeDisplayState();
}

class _WindowSizeDisplayState extends State<WindowSizeDisplay> {
  late Size windowSize;
  late Size initialSize;
  final Size minSize = Size(400, 500); // ערך קבוע מה-main.dart
  Timer? _debounceTimer;
  Stream<Size>? _sizeStream;
  StreamSubscription<Size>? _sizeSubscription;

  @override
  void initState() {
    super.initState();
    windowSize = appWindow.size;
    initialSize = appWindow.size;
    _setupSizeListener();
  }

  void _setupSizeListener() {
    // יצירת סטרים שמרווח את האירועים כדי למנוע רענונים מיותרים
    _sizeStream = Stream.periodic(
      Duration(milliseconds: 100),
      (_) => appWindow.size,
    ).distinct(
      (prev, next) => prev.width == next.width && prev.height == next.height,
    );

    // הירשמות לסטרים
    _sizeSubscription = _sizeStream?.listen((newSize) {
      if (mounted &&
          (windowSize.width != newSize.width ||
              windowSize.height != newSize.height)) {
        setState(() {
          windowSize = newSize;
        });
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _sizeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return SizedBox.shrink();

    return Positioned(
      left: 10,
      bottom: 10,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.deepPurple.withOpacity(0.7),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'גודל מומלץ: ${minSize.width.toInt()} × ${minSize.height.toInt()} px',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'גודל התחלתי: ${initialSize.width.toInt()} × ${initialSize.height.toInt()} px',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
